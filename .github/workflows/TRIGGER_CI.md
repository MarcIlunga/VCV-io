# Triggering UC Framework CI

The UC Framework CI workflow is set up to run automatically, but you can also trigger it manually.

## Automatic Triggers

The workflow runs automatically on:
- Push to `copilot/specify-uc-in-lean` branch
- Push to `main` branch
- Pull requests to `main`

## Manual Trigger

You can manually trigger the workflow from the GitHub Actions UI:

1. Go to the repository on GitHub
2. Click on "Actions" tab
3. Select "UC Framework CI" from the workflows list on the left
4. Click "Run workflow" button on the right
5. Select the branch (e.g., `copilot/specify-uc-in-lean`)
6. Click "Run workflow"

## Why Workflow Might Not Run Immediately

If you just pushed the workflow file for the first time, it may not run until:

1. **Another push is made to the branch** - Make any small change and push
2. **Manual trigger** - Use the workflow_dispatch as described above
3. **Pull request is opened** - Open a PR to main branch

## Force Trigger with Empty Commit

If the workflow doesn't start, you can force it with an empty commit:

```bash
git commit --allow-empty -m "Trigger CI workflow"
git push origin copilot/specify-uc-in-lean
```

This will trigger the workflow without making any actual code changes.

## Checking Workflow Status

Once triggered, you can monitor the workflow:

1. Go to GitHub repository → Actions tab
2. You'll see the workflow run listed
3. Click on the run to see detailed logs for each job
4. Each job (Import Check, Build UC, Test Examples, etc.) shows real-time progress

## Workflow Jobs

The UC Framework CI runs these jobs:

1. **check-uc-imports** - Verifies all UC modules are imported
2. **build-uc** - Builds each UC module
3. **test-uc-examples** - Compiles all examples
4. **verify-specification** - Checks documentation
5. **status-report** - Overall status summary

All jobs must pass for the workflow to succeed.

## Troubleshooting

If the workflow still doesn't appear:

1. **Check file location**: Workflow must be in `.github/workflows/`
2. **Check file extension**: Must be `.yml` or `.yaml`
3. **Check YAML syntax**: Validate with `yamllint .github/workflows/uc-ci.yml`
4. **Check branch**: Make sure you're on the correct branch
5. **GitHub Actions enabled**: Repository settings → Actions → General → Allow all actions

## First-Time Setup

GitHub Actions may need to be enabled for your repository:

1. Go to repository Settings
2. Click "Actions" in the left sidebar
3. Under "Actions permissions", select "Allow all actions and reusable workflows"
4. Save changes

After enabling, the workflow should run on the next push.
