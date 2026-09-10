# Contributing to intraclass

intraclass is maintained by one person. Issues are welcome; code contributions
are not solicited, for the reason given below. This page says how to send each
kind of message and what to expect.

## Contributing changes

Every estimator in intraclass must trace to a published source and agree
numerically with at least two independent implementations before it ships.
That bar is hard to hold on unsolicited pull requests, so the package does not
solicit code contributions.

If you want to change something anyway, open an issue at
<https://github.com/jmgirard/intraclass/issues> first and describe the change.
A pull request against the `main` branch is welcome after that conversation
when it is small, includes a test that fails without the change, and adds a
line to `NEWS.md`. Documentation fixes (typos, a wrong cross-reference) can go
straight to a pull request. Format R code with `air format .` before pushing;
continuous integration checks the formatting.

## Reporting a problem

Report bugs and wrong results at
<https://github.com/jmgirard/intraclass/issues>. Include:

- a minimal reproducible example, ideally with `reprex::reprex()`, or a
  description of the data layout when the data cannot be shared (how many
  subjects, raters, and ratings per cell; which columns are supplied);
- the full output of the `icc()` call, or the error message;
- the output of `packageVersion("intraclass")` and `sessionInfo()`, and the
  `engine` you used.

A result you believe is wrong is most useful with the value you expected and
where it comes from (another package, a published example, a hand calculation).

## Seeking support

Questions about which coefficient to report, how to lay out your data, or how
to read an interval also go to the issue tracker at
<https://github.com/jmgirard/intraclass/issues>; a question there helps the
next person with the same one. Start with the
[*Choosing an ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.html)
article and `choose_icc()`. For anything you would rather not post publicly,
email the maintainer at <me@jmgirard.com>.
