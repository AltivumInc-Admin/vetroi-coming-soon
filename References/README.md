# References

This folder contains peer-reviewed papers and reference materials for the VetROI pilot program.

## Adding New References

1. **Add PDF to this folder**
   - Place the PDF file in this directory

2. **Upload to S3**
   ```bash
   aws s3 cp "References/your-file.pdf" s3://vetroi-pilot-files-1760593004/references/your-file.pdf --region us-east-1
   ```

3. **Add to pilot.html**
   - Add a new file card with the reference information
   - Use the S3 key: `references/your-file.pdf`

## Current References

(Add your references here as you upload them)

