# AI-Assisted Development Policy

This project allows AI-assisted development under human review.

AI tools may be used for drafting code, documentation, tests, examples, and
maintenance notes. AI output is not accepted automatically. A human maintainer
must review, edit when necessary, test, and take responsibility for every change
before it is committed or released.

## Maintainer responsibility

The human committer is responsible for:

- verifying that the submitted code is appropriate for this project;
- checking that the contribution is compatible with the project license;
- running the documented lint, byte-compilation, and test commands;
- ensuring that AI-generated text is not copied from incompatible sources;
- adding the human `Signed-off-by` trailer when using DCO-style commits.

AI tools must not add a `Signed-off-by` trailer. That trailer is a human
certification.

## Disclosure trailer

When AI materially assisted a commit, use an `Assisted-by` trailer in the commit
message. The suggested format is:

```text
Assisted-by: ChatGPT GPT-5.5 Thinking
Signed-off-by: Your Name <you@example.com>
```

For commits not materially assisted by AI, the `Assisted-by` trailer is optional
and may be omitted.

## Scope

This policy is not currently required by MELPA. It is included to make the
project's development process explicit and to prepare for stricter downstream
review expectations.
