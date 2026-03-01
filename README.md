# cobol to java: payroll processor

This repo shows a real migration from COBOL batch processing to Java. The original ran on IBM MVS mainframes in the late 1980s. It processed weekly payroll for a manufacturing company — reading fixed-width employee records, calculating gross pay with overtime, applying tax codes, and printing a report to a sequential file.

## what the original does

`PAYROLL.cob` reads an 80-character fixed-width sequential file. Each record holds an employee ID, name, hourly rate, hours worked for the week, and a tax code (S=single, M=married, E=exempt). It calculates overtime at 1.5x for hours over 40, applies the tax rate, and writes a formatted report line. It's typical OS/VS COBOL — WORKING-STORAGE for all variables, FILE SECTION with FD entries, PERFORM loops instead of functions.

## what changed in the migration

The Java version keeps the same business logic but uses modern constructs:

- `BigDecimal` throughout — COBOL's packed decimal arithmetic doesn't map cleanly to `double`, so we use `BigDecimal` with `RoundingMode.HALF_UP` to match the original's rounding behavior
- Java records for `Employee` and `PayrollResult` — immutable, no setter sprawl
- The fixed-width parser uses the same byte offsets as the COBOL FD definition, so existing data files work without conversion
- Tax rates in a `Map` instead of an `EVALUATE` block — same logic, easier to extend

What we didn't change: the calculation logic itself. Same overtime threshold, same tax rate values, same rounding. The goal was a 1:1 functional replacement, not a redesign.

## running it

**COBOL** (requires GnuCOBOL):
```bash
cobc -x PAYROLL.cob -o payroll
./payroll
```

**Java** (requires JDK 16+):
```bash
javac PayrollProcessor.java
java PayrollProcessor employees.dat
```

The input file format is the same for both: 80-char fixed-width records matching the COBOL FD layout.

## about codemigra

We do this for a living — COBOL, VB6, Fortran, Delphi to modern languages. [codemigra.com](https://codemigra.com)
