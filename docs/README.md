## Usage

```yaml
# supported events
on:
  - push
  - pull_request
  - pull_request_target

jobs:
  job:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0 # ⚠️ required for `push` event

      # example 1: list all changed files
      - id: changed-files
        uses: ahmadnassri/action-changed-files@v1

      - run: |
          for file in ${{ steps.changed-files.outputs.files }}; do
            echo "$file has changed"
          done

      - if: contains(steps.changed-files.outputs.files, "package-lock.json")
        run: |
          echo "package-lock.json has changed"


      # example 2: detect specific changes using git pathspec
      - id: changed-files-specific
        uses: ahmadnassri/action-changed-files@v1
        with:
          pathspec: ":(top,icase,glob,attr:!vendored)src/components/*/*.jsx"

      - if: steps.changed-files-specific.outputs.changed == 'true'
        run: |
          echo "this step will only run if specific files have changed"
```

> ⚠️ when running on `push` events, a `fetch-depth` of `0` higher is required.

## `push` vs `pull_request`

when running in a `pull_request` / `pull_request_target`, the action will compare the latest commit in the PR _(`HEAD`)_ against the PR base BRANCH.

when running in a `push`, the action will compare the latest commit `HEAD` against the earliest commit `HEAD~n`, where `n` is the number of commits present in the `push` event.

## Inputs

| input       | required | default        | description                                   |
| ----------- | -------- | -------------- | --------------------------------------------- |
| `pathspec`  | ❌       | `*`            | [pathspec][] pattern used to look for changes |

> ℹ️ Learn more about [advanced pathspec usage](https://css-tricks.com/git-pathspecs-and-how-to-use-them/)

## Outputs

This action will output the following properties:

<!-- markdownlint-capture -->
<!-- markdownlint-disable MD034 -->
| property  | type     | description                           | example                                               |
| ----------| -------- | ------------------------------------- | ----------------------------------------------------- |
| `changed` | `string` | changed flag: `true` / `false`        | `true`                                                |
| `files`   | `string` | space-separated list of changed files | `README.md package.json package-lock.json`            |
| `json`    | `json`   | json array of changed files           | `["README.md", "package.json", "package-lock.json"]`  |

[pathspec]: https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefpathspecapathspec
