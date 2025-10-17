# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VetROI Coming Soon Site - A professional static website for Altivum Inc.'s VetROI platform, serving high-profile stakeholders including university administrators, recruiters, and veterans. The site includes:
- Landing page with video background
- Interest form collection system
- Password-protected pilot program portal
- Research references section

**Critical Context**: This is NOT a hackathon project. This is a professional, enterprise-grade website viewed by high-profile individuals. All changes must maintain professional quality and branding consistency.

## Deployment & Infrastructure

### AWS Amplify Hosting
- **Platform**: AWS Amplify with CloudFront CDN
- **Region**: us-east-1
- **Auto-deploy**: Pushes to `master` branch trigger automatic deployments (2-5 minutes)
- **CloudFront**: Automatically enabled for all assets (450+ edge locations globally)
- **Build**: Static HTML site (no build step required - see `amplify.yml`)

### Deployment Workflow
```bash
# All changes deploy via git push
git add <files>
git commit -m "Description"
git push origin master
# AWS Amplify automatically deploys - no manual steps needed
```

**Important**: Amplify serves everything in the root directory. CloudFront caching is automatic. Directory browsing is disabled - files must be accessed via direct URLs.

## Site Architecture

### Page Structure
1. **index.html** - Landing page with flag video background
2. **stay-informed.html** - Interest form for beta registration
3. **thank-you.html** - Post-submission confirmation page
4. **pilot.html** - Password-protected pilot program resources portal
5. **references.html** - Public research papers and references
6. **index 2.html** - Alternative landing page variant

### Authentication & APIs

#### Pilot Program (pilot.html)
- **Auth**: AWS Cognito User Pool (us-east-1_78cO1ugxw)
- **User Pool Client**: 21hctfjm11g5p9odpggbrb2kpm
- **File Downloads**: API Gateway + Lambda with S3 signed URLs
- **API Endpoint**: https://g80yjie0je.execute-api.us-east-1.amazonaws.com/prod/get-file
- **S3 Bucket**: vetroi-pilot-files-1760593004 (region: us-east-1)
- **Files**: Stored with keys like `VetROI-Pilot-Welcome-Letter.pdf`

#### Interest Form (stay-informed.html)
- **Submission**: API Gateway + Lambda + DynamoDB
- **API Endpoint**: https://g2zsa1gkjg.execute-api.us-east-1.amazonaws.com/prod/submit
- **DynamoDB Table**: vetroi-signups
- **Fields**: email (required), name (required), organization (optional), role (optional)
- **Duplicate Handling**: Returns 409 if email already exists

### Media Assets
- **Video**: `/media/us_flag.mp4` (4.3 MB, optimized for CloudFront delivery)
- **PDFs**: Pilot program materials and research papers
- **References**: `/References/` folder for academic papers

## Design System

### Color Palette
- Primary Blue: `#002868`
- Dark Blue: `#001a4d`, `#003a8c`
- White: `#FFFFFF`
- Backgrounds: Navy blue gradients (`linear-gradient(135deg, #001a4d 0%, #002868 50%, #003a8c 100%)`)

### Typography
- Headings: `'Georgia', 'Times New Roman', serif` (300 weight)
- Body: `'Helvetica Neue', 'Arial', sans-serif`
- Professional, clean styling with ample white space

### Component Patterns
All pages follow consistent patterns:
- **Card-based layouts** for file displays (pilot.html, references.html)
- **Header navigation** with Home/Logout/References links
- **Responsive design** with mobile breakpoints at 768px and 480px
- **Hover effects**: `translateY(-4px)` with enhanced shadows

## Common Development Tasks

### Adding New Reference Papers
1. Place PDF in `/References/` folder
2. Add card to `references.html`:
```html
<a href="References/Your-Paper-Name.pdf" class="file-card" target="_blank">
    <div class="file-icon">📄</div>
    <div class="file-info">
        <div class="file-name">Paper Title</div>
        <div class="file-description">Brief description</div>
    </div>
    <div class="file-meta">PDF • Size • Opens in new tab</div>
</a>
```
3. Commit and push to deploy

### Adding Pilot Program Files
1. Upload to S3:
```bash
aws s3 cp "filename.pdf" s3://vetroi-pilot-files-1760593004/filename.pdf --region us-east-1
```
2. Add card to `pilot.html` in the `files-grid`:
```html
<div class="file-card" data-file-key="filename.pdf">
    <div class="file-icon">📋</div>
    <div class="file-info">
        <div class="file-name">Display Name</div>
        <div class="file-description">Description text</div>
    </div>
    <div class="file-meta">PDF • Click to download</div>
</div>
```
3. The existing JavaScript handles authentication and signed URL generation

### Video/Media Updates
- Current video: `media/us_flag.mp4` (4.3 MB)
- Used in `index.html` and `index 2.html`
- CloudFront serves with long cache times
- To replace: Update file in `/media/`, update `<source>` tags, commit/push

## Git Workflow

### Commit Message Format
Professional commits with context:
```
Brief action-oriented title

Detailed description of changes:
- Specific change 1
- Specific change 2

Benefits/reasoning if relevant

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### What NOT to Commit
- `.DS_Store` files (macOS metadata)
- `node_modules/` (if Node.js added later)
- `.env` files with credentials
- Temporary/test files

## Testing & Verification

### Local Testing
```bash
# No build step needed - open HTML files directly
open index.html
# Or use simple HTTP server
python3 -m http.server 8000
```

### Live Site Testing
```bash
# Check CloudFront headers
curl -I https://coming-soon.altivum.ai/

# Verify References files
curl -I https://coming-soon.altivum.ai/References/The%20Impact%20of%20AI%20on%20Veteran%20Employment.pdf

# Check video delivery
curl -I https://coming-soon.altivum.ai/media/us_flag.mp4
```

### CloudFront Verification
Use the included script:
```bash
./cloudfront-verification-commands.sh
```

## AWS Configuration Files

### amplify.yml
Current build configuration (no-op build for static site):
```yaml
version: 1
frontend:
  phases:
    build:
      commands:
        - echo "Nothing to build - static HTML"
  artifacts:
    baseDirectory: /
    files:
      - '**/*'
```

### amplify-optimized.yml
Enhanced configuration with cache headers (not currently active):
- Implements cache-control headers for different file types
- Security headers (X-Frame-Options, CSP, etc.)
- See OPTIMIZATION-PLAN.md for implementation details

## Important Notes

### Professional Standards
- This site represents Altivum Inc. to university administrators, government officials, and veteran organizations
- All styling must be clean, professional, and consistent with existing design
- Test all changes before pushing (Amplify auto-deploys from master)
- Mobile responsiveness is required (significant stakeholder traffic from mobile)

### Performance Considerations
- Video is 4.3 MB MP4 (optimized from 63 MB MOV)
- CloudFront caching is automatic - no manual invalidation needed for updates
- Static assets are served from 450+ edge locations globally

### Security Context
- Pilot portal uses AWS Cognito authentication
- File downloads require valid Cognito session tokens
- API endpoints have CORS restrictions
- No sensitive data in frontend code except API endpoints (which are protected)

## Key Files Reference

- **CLOUD_ARCHITECTURE_PLAN.txt** - Complete AWS infrastructure documentation
- **OPTIMIZATION-PLAN.md** - CloudFront optimization strategies and implementation guide
- **cloudfront-verification-commands.sh** - Monitoring and verification commands
- **References/README.md** - Process for adding new research papers

## Branding

- **Company**: Altivum™ Inc.
- **Product**: VetROI
- **Tagline**: "Veteran Owned & Operated"
- **Established**: 2025
- **Domain**: altivum.ai (main), coming-soon.altivum.ai (this site)
