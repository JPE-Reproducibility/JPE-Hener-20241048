# Replication Package

**"Deterrence or Backlash? Arrests and the Dynamics of Domestic Violence"**
Sofia Amaral, Gordon B. Dahl, Timo Hener, Victoria Kaiser, Helmut Rainer

This package reproduces every figure and table in the paper and online appendix
from the raw West Midlands Police data.

---

## 1. Contents

```
replication/
  master.do                 Sets paths, checks dependencies, runs all code.
  code/
    0_install_dependencies.do  Installs required user-written commands (run once).
    01_build_sample.do      Builds the estimation dataset from raw .dta files.
    02_analysis.do          Produces all exhibits in paper order.
  README.md                 This file.
```

The raw data are not redistributed here. Place the provided files under
`$root/Rawdata/` (see `master.do`). Required raw files:

| File | Description |
|---|---|
| `res_crimes_new2.dta`      | Officer-level incident records (response actions, time stamps) |
| `warks1019_new.dta`        | Crime classifications and OS grid references |
| `caller1017.dta`           | Caller status (victim / third party) |
| `callh_vars.dta`           | Call-handler attributes |
| `crimes_201019_new.dta`    | Crime investigation database |
| `police_char_dec18.dta`    | Officer characteristics |
| `wards_matched_IV.dta`     | Ward matching to geolocation |
| `wards_population.dta`     | Ward population |
| `ward_housingtype.dta`     | Dwelling types by ward (NOMIS) |
| `datefile.dta`             | Bank-holiday calendar |
| `Analysis_Final_EJ.dta`    | British Crime Survey |

## 2. Software & dependencies

Stata 16 or later. Install the required user-written commands automatically by running the master.do.


## 3. How to run

1. Open `master.do` and set the single `global root` line to the folder that
   contains `Rawdata/`.
2. Run `master.do`.

All tables (`.tex`), figures (`.png`), and logs (`.txt`) are written to
`$path_results/`.
 
## 4. Notes on reproducibility

- Bootstrap blocks (Tables A2 and the MTE figures) use fixed seeds
  (`seed(1234)` / `set seed 12345`). The number of replications is controlled by
  `$iterations100` (100, Table A2), and
  `$iterations500` (500, Figure 3 / A2 MTE bootstrap) near the top of
  `02_analysis.do`; lower them for a faster trial run.
- Figure 1 is a hand-drawn flowchart; `02_analysis.do` prints the underlying
  shares to the log so they can be checked.

