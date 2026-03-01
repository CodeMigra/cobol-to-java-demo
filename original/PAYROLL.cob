      *----------------------------------------------------------------
      * PAYROLL.COB - Weekly Payroll Batch Processor
      * System: IBM OS/VS COBOL, MVS JES2
      * Written: 1987, Modified: 1993
      *----------------------------------------------------------------
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL.
       AUTHOR. R.HENDERSON.
       DATE-WRITTEN. 1987-03-12.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMPLOYEE-FILE
               ASSIGN TO UT-S-EMPFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT PAYROLL-REPORT
               ASSIGN TO UT-S-PAYRPT
               ORGANIZATION IS SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD EMPLOYEE-FILE
           BLOCK CONTAINS 0 RECORDS
           LABEL RECORDS ARE STANDARD
           RECORDING MODE IS F
           RECORD CONTAINS 80 CHARACTERS.
       01 EMPLOYEE-RECORD.
          05 EMP-ID            PIC X(6).
          05 EMP-LAST-NAME     PIC X(20).
          05 EMP-FIRST-NAME    PIC X(15).
          05 EMP-HOURLY-RATE   PIC 9(4)V99.
          05 EMP-HOURS-WORKED  PIC 9(3)V9.
          05 EMP-TAX-CODE      PIC X(2).
          05 EMP-DEPARTMENT    PIC X(4).
          05 FILLER            PIC X(24).

       FD PAYROLL-REPORT
           LABEL RECORDS ARE OMITTED
           RECORD CONTAINS 133 CHARACTERS.
       01 REPORT-LINE           PIC X(133).

       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS        PIC XX VALUE SPACES.
       01 WS-EOF-FLAG           PIC X VALUE 'N'.
          88 END-OF-FILE        VALUE 'Y'.
       01 WS-RECORD-COUNT       PIC 9(5) VALUE ZERO.
       01 WS-TOTAL-GROSS        PIC 9(9)V99 VALUE ZERO.
       01 WS-TOTAL-NET          PIC 9(9)V99 VALUE ZERO.

       01 WS-CALC-AREA.
          05 WS-GROSS-PAY      PIC 9(7)V99.
          05 WS-OVERTIME-HRS   PIC 9(3)V9.
          05 WS-OVERTIME-PAY   PIC 9(6)V99.
          05 WS-TAX-AMOUNT     PIC 9(6)V99.
          05 WS-NET-PAY        PIC 9(7)V99.

       01 WS-TAX-RATES.
          05 WS-TAX-S          PIC V9999 VALUE .2200.
          05 WS-TAX-M          PIC V9999 VALUE .1800.
          05 WS-TAX-E          PIC V9999 VALUE .2500.

       01 DETAIL-LINE.
          05 DL-EMP-ID         PIC X(6).
          05 FILLER            PIC X(2) VALUE SPACES.
          05 DL-NAME           PIC X(25).
          05 FILLER            PIC X(2) VALUE SPACES.
          05 DL-HOURS          PIC ZZ9.9.
          05 FILLER            PIC X(2) VALUE SPACES.
          05 DL-RATE           PIC ZZ9.99.
          05 FILLER            PIC X(2) VALUE SPACES.
          05 DL-GROSS          PIC ZZZ,ZZ9.99.
          05 FILLER            PIC X(2) VALUE SPACES.
          05 DL-TAX            PIC ZZZ,ZZ9.99.
          05 FILLER            PIC X(2) VALUE SPACES.
          05 DL-NET            PIC ZZZ,ZZ9.99.
          05 FILLER            PIC X(44) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL END-OF-FILE
           PERFORM 3000-WRAPUP
           STOP RUN.

       1000-INIT.
           OPEN INPUT  EMPLOYEE-FILE
                OUTPUT PAYROLL-REPORT
           READ EMPLOYEE-FILE
               AT END MOVE 'Y' TO WS-EOF-FLAG
           END-READ.

       2000-PROCESS.
           ADD 1 TO WS-RECORD-COUNT
           PERFORM 2100-CALC-PAY
           PERFORM 2200-WRITE-LINE
           READ EMPLOYEE-FILE
               AT END MOVE 'Y' TO WS-EOF-FLAG
           END-READ.

       2100-CALC-PAY.
           IF EMP-HOURS-WORKED > 40
               SUBTRACT 40 FROM EMP-HOURS-WORKED
                   GIVING WS-OVERTIME-HRS
               MULTIPLY EMP-HOURLY-RATE BY 40
                   GIVING WS-GROSS-PAY
               MULTIPLY EMP-HOURLY-RATE BY 1.5
                   GIVING WS-OVERTIME-PAY
               MULTIPLY WS-OVERTIME-PAY BY WS-OVERTIME-HRS
                   GIVING WS-OVERTIME-PAY
               ADD WS-OVERTIME-PAY TO WS-GROSS-PAY
           ELSE
               MULTIPLY EMP-HOURLY-RATE BY EMP-HOURS-WORKED
                   GIVING WS-GROSS-PAY
           END-IF
           EVALUATE EMP-TAX-CODE
               WHEN 'S ' MULTIPLY WS-GROSS-PAY BY WS-TAX-S
                             GIVING WS-TAX-AMOUNT
               WHEN 'M ' MULTIPLY WS-GROSS-PAY BY WS-TAX-M
                             GIVING WS-TAX-AMOUNT
               WHEN 'E ' MULTIPLY WS-GROSS-PAY BY WS-TAX-E
                             GIVING WS-TAX-AMOUNT
               WHEN OTHER MOVE ZERO TO WS-TAX-AMOUNT
           END-EVALUATE
           SUBTRACT WS-TAX-AMOUNT FROM WS-GROSS-PAY
               GIVING WS-NET-PAY
           ADD WS-GROSS-PAY TO WS-TOTAL-GROSS
           ADD WS-NET-PAY   TO WS-TOTAL-NET.

       2200-WRITE-LINE.
           MOVE EMP-ID           TO DL-EMP-ID
           MOVE EMP-LAST-NAME    TO DL-NAME
           MOVE EMP-HOURS-WORKED TO DL-HOURS
           MOVE EMP-HOURLY-RATE  TO DL-RATE
           MOVE WS-GROSS-PAY     TO DL-GROSS
           MOVE WS-TAX-AMOUNT    TO DL-TAX
           MOVE WS-NET-PAY       TO DL-NET
           WRITE REPORT-LINE FROM DETAIL-LINE.

       3000-WRAPUP.
           CLOSE EMPLOYEE-FILE
                 PAYROLL-REPORT.
