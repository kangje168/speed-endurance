# Publish the privacy policy on GitHub Pages

Published under GitHub account `kangje168`. Verified on October 13, 2026: public HTTPS request returned HTTP 200, with the expected policy title and support email.

1. Create a public repository named `speed-endurance-privacy` under `kangje168`.
2. Upload the contents of `release/github-pages/` to the repository root on `main`: `index.html`, `.nojekyll`, and `README.md`. Upload the contents, not the enclosing folder.
3. In the repository, open **Settings > Pages**. Choose **Deploy from a branch**, select **main** and **/(root)**, then save.
4. Wait for deployment to complete, then open the site in a signed-out browser and check the policy and support email.
5. Use the verified public URL in the Connect IQ submission:

   `https://kangje168.github.io/speed-endurance-privacy/`

The URL above is live and verified. The steps above document the deployment setup for future maintenance.

Official instructions: [Creating a GitHub Pages site](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site).

When the policy changes, update `release/privacy.html`, copy it to `release/github-pages/index.html`, and publish that file again.
