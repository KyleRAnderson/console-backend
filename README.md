# Reindeer Hunt Console

## Setup

### Prerequisites

-   Correct Ruby and Rails installed
-   Yarn package manager

### Fast setup

```bash
bundle
yarn
```

Then, generate a secret using `rake secret`.
In the root directory of the project, add a `.env` file with the following entry:

```env
export DEVISE_JWT_SECRET_KEY=[key_generated_by_rake_secret]
```

#### Debugging

In order to be able to use launch configurations to debug, the recommended extensions should be installed, and the `ruby-debug-ide` extension will also be needed:

```bash
gem install ruby-debug-ide
```
