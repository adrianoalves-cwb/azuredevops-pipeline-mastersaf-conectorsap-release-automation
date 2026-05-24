# Mastersaf ConectorSAP Update Automation

## Overview

This repository automates the update flow for Thomson Reuters Mastersaf ConectorSAP in Azure DevOps.

The process starts in `azure-pipelines.yml`, which runs on a daily schedule for the `qa` and `main` branches. That pipeline logs in to the Thomson Reuters portal, reads the currently published ConectorSAP version, compares it with the installed-version registry file, and publishes a small artifact that tells the next pipeline whether a new release exists.

When a new version is detected, `mastersaf-conector-sap-fm.yaml` is triggered through a pipeline resource. It downloads the installation package, normalizes and repackages the extracted ConectorSAP files, and deploys the update. QA is intended to update automatically. Production is modeled as a deployment job against the `Mastersaf Prod` environment, where Azure DevOps approvals and checks can be configured so the release waits for manual approval.

## End-to-end flow

1. `azure-pipelines.yml` runs on schedule for `qa` and `main`.
2. Robot Framework opens the Thomson Reuters website and reads the current ConectorSAP version.
3. `scripts/CheckVersionFileSendEmail.ps1` checks whether the version already exists in the environment version file.
4. If the version is new, the script updates the version file, sends a notification email, and publishes `Version.txt` as a build artifact.
5. `mastersaf-conector-sap-fm.yaml` is triggered by the first pipeline artifact.
6. `templates/versionValidation-template.yml` downloads the `Version.txt` artifact and `scripts/ValidateMastersafVersion.ps1` decides whether deployment should continue.
7. Robot Framework downloads the new Thomson Reuters ZIP package.
8. `scripts/UnzipIntegradorDFeConectorSAP.ps1` extracts and normalizes the installation into a clean `ConectorSAP` folder.
9. Placeholder SAP dependency files from `sap_dependencies_placeholder_win` are copied into the package. In private environments these placeholders should be replaced with the real vendor files before deployment.
10. The QA deployment runs automatically through `templates/DeploySAPConnector.yaml`.
11. The production deployment uses the same deployment template and is expected to pause on Azure DevOps environment approval checks before applying the release.
12. Backup, cleanup, validation, and email notification steps run as part of the deployment template.

## Azure DevOps pipeline roles

### `azure-pipelines.yml`

Purpose: detect whether Thomson Reuters published a new ConectorSAP version.

Key behavior:

- Runs daily at 07:00 UTC for `main` and `qa`.
- Installs Python and Robot Framework dependencies.
- Replaces tokenized credentials and locators in the Robot files.
- Runs `robot_framework/GetVerstion.robot` to capture the website version.
- Executes `scripts/CheckVersionFileSendEmail.ps1` for QA or Production, including an email notification that Thomson Reuters has published a new ConectorSAP version.
- Publishes `Version.txt` so downstream automation can decide whether to continue.

### `mastersaf-conector-sap-fm.yaml`

Purpose: download, prepare, and deploy the new ConectorSAP package when a new version is available.

Key behavior:

- Starts from the artifact produced by the version-check pipeline.
- Uses `templates/versionValidation-template.yml` to stop early when the upstream pipeline reported `UpToDate`.
- Runs Robot Framework to download the Thomson Reuters ZIP.
- Calls `scripts/UnzipIntegradorDFeConectorSAP.ps1` to rebuild a clean installation package.
- Copies placeholder SAP dependency files from `sap_dependencies_placeholder_win`.
- Publishes a deployable `ConectorSAP.zip` artifact.
- Deploys to QA automatically through `templates/DeploySAPConnector.yaml`.
- Deploys to Production through the same template, with approval expected to be enforced by the Azure DevOps environment configuration.

## Required Azure DevOps configuration

The YAML files rely on Azure DevOps configuration outside this repository.

- Variable groups:
	- `mastersaf-conector-sap-tr-login`
	- `mastersaf-conector-sap`
	- `mastersaf-conector-sap-fm-qa`
	- `mastersaf-conector-sap-fm-prod`
- Agent pools:
	- `QA_SERVER`
	- `PRODUCTION_SERVER`
- Environments:
	- `Mastersaf QA`
	- `Mastersaf Prod`
- The `Mastersaf Prod` environment should have approval checks configured if production must wait for manual approval.
- The Thomson Reuters website credentials, SMTP server, installation paths, service names, and version file paths must be provided through variable groups.

## SAP dependency placeholders

This public repository does not contain licensed SAP connector binaries.

The folder `sap_dependencies_placeholder_win` contains placeholder files only. Replace them with the real vendor files in a private build context before running a deployment that must install working SAP libraries.

If you want to keep private local copies outside Git, place them in `sap_dependencies_private_win`, which is ignored by Git.

## Repository file guide

### Root files

- `azure-pipelines.yml`: scheduled pipeline that reads the Thomson Reuters version and decides whether a new release exists.
- `mastersaf-conector-sap-fm.yaml`: downstream pipeline that downloads, prepares, and deploys ConectorSAP.
- `README.md`: repository documentation.
- `.gitignore`: ignores the private dependency folder used for non-public vendor files.

### `robot_framework/`

- `GetVerstion.robot`: logs in to the Thomson Reuters portal and stores the visible ConectorSAP version in `Version.txt`.
- `DownloadZipFile.robot`: logs in to the Thomson Reuters portal and downloads the current ConectorSAP ZIP package.
- `SeleniumExtension.py`: custom Robot keyword that configures a Firefox profile and the download directory.

### `scripts/`

- `CheckVersionFileSendEmail.ps1`: checks whether the website version already exists in the version registry file, updates the file when needed, writes `Version.txt`, and sends notification email.
- `ValidateMastersafVersion.ps1`: reads the upstream artifact and decides whether the deployment pipeline should continue or skip.
- `UnzipIntegradorDFeConectorSAP.ps1`: finds the downloaded installer ZIP, extracts nested ZIP content, removes non-deployable files, and rebuilds a clean `ConectorSAP` folder.
- `CleanupBackupFiles.ps1`: removes old backup ZIP files when the backup folder grows beyond the configured retention behavior.
- `CreateBackup.ps1`: creates a ZIP backup of the current ConectorSAP installation before deployment.
- `ValidateInstallation.ps1`: checks the deployed version in the runtime log and fails the deployment if the installed version does not match the expected one.
- `SendEmail.ps1`: sends success or failure email notifications after deployment.

### `templates/`

- `DeploySAPConnector.yaml`: main deployment template used by QA and Production.
	- Checks out the repository and logs the source branch.
	- Extracts the `ConectorSAP.zip` artifact into a staging folder.
	- Stops the target Windows service before file replacement.
	- Runs backup housekeeping to remove old backup ZIP files.
	- Creates a fresh backup of the current ConectorSAP installation.
	- Copies `bin`, `dll`, `esapi`, and `lib` folders into the installation directory.
	- Removes old `*.trc` files from the installation root.
	- Renames existing log files with a timestamp.
	- Starts the Windows service again and waits for startup.
	- Validates the installed version by reading runtime logs.
	- Cleans temporary pipeline files from the build agent.
	- Sends a success email when deployment succeeds.
	- Sends a failure email when deployment fails.
- `versionValidation-template.yml`: downloads the artifact from pipeline `763` and executes `ValidateMastersafVersion.ps1`.

### `sap_dependencies_placeholder_win/`

- `placeholder-sap-library.dll`: placeholder for the SAP native library.
- `placeholder-sap-library.jar`: placeholder for the SAP Java library.
- `placeholder-sap-library.pdb`: placeholder for optional debug symbols.
- `placeholder-sap-library-manifest.mf`: placeholder manifest file.

## Operational notes

- `CheckVersionFileSendEmail.ps1` currently writes `UpToDate` to the artifact when the environment already has the current version, allowing the downstream pipeline to skip work.
- The deployment template clears and recopies the `lib` directory, so the SAP dependency files packaged by the build must be correct before deployment starts.
- `ValidateInstallation.ps1` reads `logs/conector-erp.log` to confirm the deployed version, so the service must write the expected startup log entry.
- `SendEmail.ps1` translates `refs/heads/qa` to `QA` and `refs/heads/main` to `PROD` in notification messages.

## How to work with this repository

1. Update variable groups, service paths, SMTP settings, and environment approvals in Azure DevOps.
2. Replace placeholder SAP dependency files in a private build context.
3. Keep Robot Framework locators in sync with the Thomson Reuters website.
4. Review deployment template behavior before changing installation structure, service names, or log parsing rules.

