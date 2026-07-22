# Deployment Fix Plan ✅

## 1. ✅ Fix cert-manager webhook issue
- ✅ Updated `deploy.sh` to wait for webhook pod before proceeding

## 2. ✅ Update values-production.yaml with actual domain and email
- ✅ Domain: `store.amyxjack02.shop`
- ✅ Email: `gaurav.cloud000@gmail.com`

## 3. ⬜ DNS Setup (manual step — see instructions below)
After deployment succeeds, create a DNS record.

## 4. ⬜ Re-deploy (manual step)
Push to GitHub and run on your K8s cluster.


