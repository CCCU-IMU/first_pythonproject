# Contributing

This project welcomes practical scripts, test fixtures, and documentation that help reproduce bioinformatics analyses.

## Script rules

- Prefer parameterized input/output paths over hard-coded local paths.
- Keep large raw data, private samples, and intermediate result folders out of git.
- Add a small synthetic example whenever possible.
- For R scripts, list required packages in `r_requirements.R` or the script header.
- For Python code in `first_pythonproject/`, add or update `tests/`.

## Pull request checklist

- The script has a clear purpose and expected input format.
- The output file names and directories are documented.
- `python -m unittest discover -s tests` passes when Python package code changes.
- Sensitive research data and local absolute paths are not committed.
