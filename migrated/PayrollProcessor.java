import java.io.*;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

public class PayrollProcessor {

    private static final BigDecimal OVERTIME_THRESHOLD = new BigDecimal("40.0");
    private static final BigDecimal OVERTIME_MULTIPLIER = new BigDecimal("1.5");

    private static final Map<String, BigDecimal> TAX_RATES = Map.of(
        "S", new BigDecimal("0.2200"),
        "M", new BigDecimal("0.1800"),
        "E", new BigDecimal("0.2500")
    );

    public record Employee(
        String id,
        String lastName,
        String firstName,
        BigDecimal hourlyRate,
        BigDecimal hoursWorked,
        String taxCode,
        String department
    ) {}

    public record PayrollResult(
        Employee employee,
        BigDecimal grossPay,
        BigDecimal taxAmount,
        BigDecimal netPay
    ) {}

    public PayrollResult calculate(Employee emp) {
        BigDecimal grossPay;

        if (emp.hoursWorked().compareTo(OVERTIME_THRESHOLD) > 0) {
            BigDecimal regularPay = emp.hourlyRate().multiply(OVERTIME_THRESHOLD);
            BigDecimal overtimeHours = emp.hoursWorked().subtract(OVERTIME_THRESHOLD);
            BigDecimal overtimeRate = emp.hourlyRate().multiply(OVERTIME_MULTIPLIER);
            BigDecimal overtimePay = overtimeRate.multiply(overtimeHours);
            grossPay = regularPay.add(overtimePay);
        } else {
            grossPay = emp.hourlyRate().multiply(emp.hoursWorked());
        }

        grossPay = grossPay.setScale(2, RoundingMode.HALF_UP);

        BigDecimal taxRate = TAX_RATES.getOrDefault(emp.taxCode().trim(), BigDecimal.ZERO);
        BigDecimal taxAmount = grossPay.multiply(taxRate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal netPay = grossPay.subtract(taxAmount);

        return new PayrollResult(emp, grossPay, taxAmount, netPay);
    }

    public List<PayrollResult> processFile(String inputPath) throws IOException {
        List<PayrollResult> results = new ArrayList<>();

        try (BufferedReader reader = new BufferedReader(new FileReader(inputPath))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.length() < 57) continue;  // minimum length to reach dept field (substring 53-57)
                Employee emp = parseRecord(line);
                results.add(calculate(emp));
            }
        }

        return results;
    }

    private Employee parseRecord(String record) {
        // Fixed-width layout matches original COBOL FD definition
        // COBOL PIC 9(4)V99 = 6 chars with implied 2 decimal places (e.g. "001500" = 15.00)
        // COBOL PIC 9(3)V9  = 4 chars with implied 1 decimal place  (e.g. "0400" = 40.0)
        String id         = record.substring(0, 6).trim();
        String lastName   = record.substring(6, 26).trim();
        String firstName  = record.substring(26, 41).trim();
        BigDecimal rate   = new BigDecimal(record.substring(41, 47).trim().replace(",", ""))
                                .movePointLeft(2);   // PIC 9(4)V99 → implied 2 decimal places
        BigDecimal hours  = new BigDecimal(record.substring(47, 51).trim())
                                .movePointLeft(1);   // PIC 9(3)V9  → implied 1 decimal place
        String taxCode    = record.substring(51, 53).trim();
        String dept       = record.substring(53, 57).trim();

        return new Employee(id, lastName, firstName, rate, hours, taxCode, dept);
    }

    public void printReport(List<PayrollResult> results) {
        System.out.printf("%-6s  %-20s  %6s  %7s  %10s  %10s  %10s%n",
            "ID", "Name", "Hours", "Rate", "Gross", "Tax", "Net");
        System.out.println("-".repeat(80));

        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalNet   = BigDecimal.ZERO;

        for (PayrollResult r : results) {
            System.out.printf("%-6s  %-20s  %6.1f  %7.2f  %10.2f  %10.2f  %10.2f%n",
                r.employee().id(),
                r.employee().lastName(),
                r.employee().hoursWorked(),
                r.employee().hourlyRate(),
                r.grossPay(),
                r.taxAmount(),
                r.netPay());
            totalGross = totalGross.add(r.grossPay());
            totalNet   = totalNet.add(r.netPay());
        }

        System.out.println("-".repeat(80));
        System.out.printf("%-6s  %-20s  %6s  %7s  %10.2f  %10s  %10.2f%n",
            "TOTAL", "", "", "", totalGross, "", totalNet);
        System.out.printf("%nRecords processed: %d%n", results.size());
    }

    public static void main(String[] args) throws IOException {
        if (args.length < 1) {
            System.err.println("Usage: PayrollProcessor <input-file>");
            System.exit(1);
        }
        PayrollProcessor processor = new PayrollProcessor();
        List<PayrollResult> results = processor.processFile(args[0]);
        processor.printReport(results);
    }
}
