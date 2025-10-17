#!/bin/bash
#
# CloudFront Verification Commands for Amplify App
# Usage: Review and run these commands to verify CloudFront configuration
#

set -e

echo "=========================================="
echo "AWS Amplify + CloudFront Verification"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Find Amplify App
echo -e "${YELLOW}Step 1: Finding Amplify App${NC}"
echo "Command: aws amplify list-apps --region us-east-1"
echo ""
APP_INFO=$(aws amplify list-apps --region us-east-1 --query 'apps[?name==`vetroi-coming-soon`].[appId,name,defaultDomain]' --output json)
echo "Result: $APP_INFO"
echo ""

# Extract App ID (you'll need to set this manually after first run)
# APP_ID="YOUR_APP_ID_HERE"

echo -e "${YELLOW}Step 2: Get App Domain Information${NC}"
echo "Command: aws amplify get-app --app-id \$APP_ID --region us-east-1"
echo "(Run this after you have your APP_ID from Step 1)"
echo ""

# 3. List CloudFront Distributions
echo -e "${YELLOW}Step 3: List All CloudFront Distributions${NC}"
echo "Command: aws cloudfront list-distributions --output table"
echo ""
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,Origins.Items[0].DomainName,Enabled,Status]' --output table
echo ""

# 4. Find distribution matching your domain
echo -e "${YELLOW}Step 4: Find Your Distribution${NC}"
echo "Look for distribution with DomainName containing 'amplifyapp.com' in the table above"
echo "Or run: aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Origins.Items[0].DomainName,\`amplifyapp\`)].{ID:Id,Domain:DomainName,Origin:Origins.Items[0].DomainName}' --output table"
echo ""

# 5. Get specific distribution details (requires DISTRIBUTION_ID)
echo -e "${YELLOW}Step 5: Get Distribution Details${NC}"
echo "After identifying your distribution ID from Step 4, run:"
echo ""
echo "export DIST_ID=\"YOUR_DISTRIBUTION_ID\""
echo ""
echo "aws cloudfront get-distribution-config --id \$DIST_ID --query 'DistributionConfig.{Compress:DefaultCacheBehavior.Compress,ViewerProtocol:DefaultCacheBehavior.ViewerProtocolPolicy,CachePolicyId:DefaultCacheBehavior.CachePolicyId,PriceClass:PriceClass}' --output json"
echo ""

# 6. Test CloudFront headers
echo -e "${YELLOW}Step 6: Test Live Site Headers${NC}"
echo "Run these curl commands to verify CloudFront is serving your site:"
echo ""
echo "# Test HTML caching"
echo "curl -I https://coming-soon.altivum.ai/"
echo ""
echo "# Test PDF caching"
echo "curl -I https://coming-soon.altivum.ai/VetROI%20Pilot%20Welcome%20Letter.pdf"
echo ""
echo "# Test video (if migrated to Amplify)"
echo "curl -I https://coming-soon.altivum.ai/media/us_flag.mov"
echo ""

# 7. Check for CloudFront headers
echo -e "${YELLOW}Step 7: Verify CloudFront Headers (Look for these)${NC}"
echo "Expected headers in curl output:"
echo "  - x-cache: Hit from cloudfront (or Miss from cloudfront on first request)"
echo "  - x-amz-cf-id: <some-request-id>"
echo "  - via: 1.1 <cloudfront-id>.cloudfront.net"
echo ""

# 8. CloudWatch metrics
echo -e "${YELLOW}Step 8: Check CloudFront Cache Performance${NC}"
echo "aws cloudwatch get-metric-statistics \\"
echo "  --namespace AWS/CloudFront \\"
echo "  --metric-name CacheHitRate \\"
echo "  --dimensions Name=DistributionId,Value=\$DIST_ID \\"
echo "  --start-time \$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \\"
echo "  --end-time \$(date -u +%Y-%m-%dT%H:%M:%S) \\"
echo "  --period 3600 \\"
echo "  --statistics Average,Maximum,Minimum \\"
echo "  --output table"
echo ""

# 9. Check S3 bucket for external video
echo -e "${YELLOW}Step 9: Check External S3 Video Asset${NC}"
echo "aws s3 ls s3://altivum-media-assets/ --region us-east-1"
echo ""
echo "# Get video file size"
echo "aws s3 ls s3://altivum-media-assets/us_flag.mov --region us-east-1 --human-readable --summarize"
echo ""

# 10. Invalidate CloudFront cache (after updates)
echo -e "${YELLOW}Step 10: Invalidate CloudFront Cache (Use after deployments)${NC}"
echo "aws cloudfront create-invalidation \\"
echo "  --distribution-id \$DIST_ID \\"
echo "  --paths '/*'"
echo ""
echo "Note: First 1,000 invalidations per month are free"
echo ""

echo -e "${GREEN}=========================================="
echo "Verification Complete!"
echo "==========================================${NC}"
echo ""
echo "NEXT STEPS:"
echo "1. Run commands above to identify your DIST_ID"
echo "2. Review OPTIMIZATION-PLAN.md for implementation steps"
echo "3. Update amplify.yml with optimized configuration"
echo "4. Consider migrating video to Amplify project for better caching"
echo ""
