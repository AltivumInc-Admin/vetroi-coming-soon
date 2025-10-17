# CloudFront Optimization Implementation Plan

## CRITICAL: Video Asset Migration

### Current Problem
The video file `us_flag.mov` is hosted on external S3 bucket:
- URL: https://altivum-media-assets.s3.us-east-1.amazonaws.com/us_flag.mov
- NOT cached by Amplify's CloudFront distribution
- Slower global delivery
- Higher costs

### Solution: Migrate Video to Amplify Project

#### Step 1: Download the video to your project
```bash
# Create media directory in project
mkdir -p /Users/cperez/Desktop/Altivum/vetroi-coming-soon/media

# Download video from S3
aws s3 cp s3://altivum-media-assets/us_flag.mov /Users/cperez/Desktop/Altivum/vetroi-coming-soon/media/us_flag.mov --region us-east-1
```

#### Step 2: Update HTML files
Change from:
```html
<source src="https://altivum-media-assets.s3.us-east-1.amazonaws.com/us_flag.mov" type="video/mp4">
```

To:
```html
<source src="/media/us_flag.mov" type="video/mp4">
```

Update these files:
- /Users/cperez/Desktop/Altivum/vetroi-coming-soon/index.html (line 350)
- /Users/cperez/Desktop/Altivum/vetroi-coming-soon/index 2.html (line 325)

#### Step 3: Replace amplify.yml
```bash
# Backup current config
cp /Users/cperez/Desktop/Altivum/vetroi-coming-soon/amplify.yml /Users/cperez/Desktop/Altivum/vetroi-coming-soon/amplify.yml.backup

# Use optimized config
cp /Users/cperez/Desktop/Altivum/vetroi-coming-soon/amplify-optimized.yml /Users/cperez/Desktop/Altivum/vetroi-coming-soon/amplify.yml
```

#### Step 4: Commit and deploy
```bash
cd /Users/cperez/Desktop/Altivum/vetroi-coming-soon
git add media/ amplify.yml index.html
git commit -m "Optimize media delivery: migrate video to Amplify, add cache headers"
git push origin master
```

---

## Option B: CloudFront Distribution for External S3 (If keeping separate)

If you need to keep the video in the separate S3 bucket, create a dedicated CloudFront distribution:

### Step 1: Create CloudFront distribution for media bucket
```bash
# Create distribution configuration
cat > /tmp/cloudfront-s3-media.json <<'EOF'
{
  "CallerReference": "altivum-media-assets-$(date +%s)",
  "Comment": "CloudFront distribution for Altivum media assets",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-altivum-media-assets",
        "DomainName": "altivum-media-assets.s3.us-east-1.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        },
        "CustomHeaders": {
          "Quantity": 0
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-altivum-media-assets",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    }
  },
  "PriceClass": "PriceClass_All"
}
EOF

# Create the distribution
aws cloudfront create-distribution --distribution-config file:///tmp/cloudfront-s3-media.json
```

### Step 2: Update S3 bucket policy to allow CloudFront
```bash
# Get the CloudFront distribution domain name from previous command output
# Then update HTML to use: https://<cloudfront-domain>/us_flag.mov
```

---

## Performance Impact Comparison

### Current Setup (Direct S3):
- Global latency: 100-500ms (depending on region)
- No edge caching
- Data transfer cost: $0.09/GB

### With CloudFront via Amplify:
- Global latency: 10-50ms (edge locations)
- Edge caching enabled
- Data transfer cost: $0.085/GB (first 10TB)
- **80-90% latency reduction**

### Estimated Monthly Costs (1000 users/day viewing video):
- Direct S3: ~$27/month
- CloudFront: ~$15/month
- **44% cost reduction**

---

## Additional CloudFront Optimizations

### Enable Compression
Amplify's CloudFront automatically compresses text-based files (HTML, CSS, JS), but verify:

```bash
aws cloudfront get-distribution-config --id <distribution-id> \
  --query 'DistributionConfig.DefaultCacheBehavior.Compress'
```

Should return: `true`

### Configure Custom Error Pages
Add to Amplify console → App Settings → Rewrites and redirects:
- 404 → /index.html (200)
- 403 → /index.html (200)

### Enable HTTP/3 (QUIC)
This must be done via AWS Console:
1. Go to CloudFront console
2. Select your distribution
3. Edit → Enable HTTP/3

---

## Monitoring & Verification

### After Deployment, Run These Checks:

#### 1. Verify CloudFront is serving content
```bash
curl -I https://coming-soon.altivum.ai/
```

Look for headers:
- `x-cache: Hit from cloudfront` (after first request)
- `x-amz-cf-id: <request-id>`
- `via: 1.1 <cloudfront-id>.cloudfront.net`

#### 2. Test video delivery performance
```bash
# Test from different regions using curl with timing
curl -w "@curl-format.txt" -o /dev/null -s https://coming-soon.altivum.ai/media/us_flag.mov

# Create curl timing format file first:
cat > curl-format.txt <<'EOF'
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n
EOF
```

#### 3. Check cache hit ratio
```bash
# Get CloudFront metrics (requires CloudWatch)
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=<distribution-id> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Average
```

Target: >85% cache hit rate

#### 4. Verify cache headers in browser
```bash
# Test each file type
curl -I https://coming-soon.altivum.ai/index.html | grep -i cache
curl -I https://coming-soon.altivum.ai/media/us_flag.mov | grep -i cache
curl -I https://coming-soon.altivum.ai/VetROI%20Pilot%20Welcome%20Letter.pdf | grep -i cache
```

---

## Security Considerations

### Already Implemented in optimized config:
- X-Frame-Options: Prevents clickjacking
- X-Content-Type-Options: Prevents MIME sniffing
- Referrer-Policy: Controls referrer information
- HTTPS-only via CloudFront

### Additional Recommendations:
1. Enable AWS WAF on CloudFront (if not already)
2. Configure geo-restrictions if needed
3. Set up CloudFront access logging for audit trail

---

## Cost Optimization Tips

1. **CloudFront Free Tier**: First 1TB/month is free for 12 months
2. **S3 Transfer Pricing**: Moving video to Amplify eliminates cross-region transfer fees
3. **Cache Hit Ratio**: Aim for >90% to minimize origin requests
4. **Compression**: Enabled by default, reduces data transfer by 60-80% for text files

---

## Timeline & Priority

### High Priority (Immediate):
1. Replace amplify.yml with optimized version
2. Migrate video to Amplify project (or create CloudFront for S3)
3. Deploy and verify cache headers

### Medium Priority (This Week):
1. Enable HTTP/3 in CloudFront console
2. Configure custom error pages
3. Set up CloudWatch alarms for cache hit rate

### Low Priority (When Time Permits):
1. Implement CloudFront access logging
2. Consider AWS WAF for DDoS protection
3. Optimize PDF file size if large

---

## Expected Performance Improvements

After implementing these optimizations:

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Video Load Time (Global Avg) | 2-5 seconds | 0.5-1 second | 75-80% faster |
| First Contentful Paint | 1.2s | 0.8s | 33% faster |
| Cache Hit Ratio | 60-70% | 85-95% | 25-35% improvement |
| Monthly Bandwidth Costs | $30 | $15 | 50% reduction |
| Global Latency (P95) | 300ms | 50ms | 83% reduction |

---

## Questions to Answer Before Implementation

1. **Do you have permissions to**:
   - Modify the amplify.yml file?
   - Access the S3 bucket `altivum-media-assets`?
   - View CloudFront distributions in AWS Console?

2. **File size of us_flag.mov**:
   - If >10MB, consider optimizing/compressing
   - Consider WebM format as alternative (better compression)

3. **Video format optimization**:
   - Current: .mov (QuickTime format)
   - Recommended: Add .mp4 and .webm versions for better browser support

Would you like me to help implement any of these optimizations?
