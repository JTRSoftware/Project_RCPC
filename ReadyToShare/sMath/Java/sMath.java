package jtrsoftware.math;

import java.io.*;

public class SMath {
    public static char decimalSeparator = '.';

    public static boolean isNegative(String sV) {
        return sV != null && sV.startsWith("-");
    }

    public static String getAbs(String sV) {
        return isNegative(sV) ? sV.substring(1) : sV;
    }

    public static String cleanNumber(String sV) {
        boolean neg = isNegative(sV);
        String val = getAbs(sV);
        if (val == null || val.isEmpty()) return "0";

        StringBuilder sb = new StringBuilder(val);
        while (sb.length() > 1 && sb.charAt(0) == '0' && sb.charAt(1) != decimalSeparator) {
            sb.deleteCharAt(0);
        }

        int dotPos = sb.indexOf(String.valueOf(decimalSeparator));
        if (dotPos >= 0) {
            while (sb.length() > dotPos + 1 && sb.charAt(sb.length() - 1) == '0') {
                sb.deleteCharAt(sb.length() - 1);
            }
            if (sb.charAt(sb.length() - 1) == decimalSeparator) {
                sb.deleteCharAt(sb.length() - 1);
            }
        }

        String res = sb.toString();
        if (res.isEmpty() || res.equals(String.valueOf(decimalSeparator))) res = "0";

        return (neg && !res.equals("0")) ? "-" + res : res;
    }

    private static String[] alignStrings(String sA, String sB) {
        int dotA = sA.indexOf(decimalSeparator);
        int dotB = sB.indexOf(decimalSeparator);
        int decA = (dotA < 0) ? 0 : sA.length() - dotA - 1;
        int decB = (dotB < 0) ? 0 : sB.length() - dotB - 1;
        StringBuilder sbA = new StringBuilder(sA);
        StringBuilder sbB = new StringBuilder(sB);
        while (decA < decB) {
            if (dotA < 0) { sbA.append(decimalSeparator); dotA = sbA.length() - 1; }
            sbA.append('0'); decA++;
        }
        while (decB < decA) {
            if (dotB < 0) { sbB.append(decimalSeparator); dotB = sbB.length() - 1; }
            sbB.append('0'); decB++;
        }
        int intA = (dotA < 0) ? sbA.length() : dotA;
        int intB = (dotB < 0) ? sbB.length() : dotB;
        while (intA < intB) { sbA.insert(0, '0'); intA++; }
        while (intB < intA) { sbB.insert(0, '0'); intB++; }
        return new String[]{sbA.toString(), sbB.toString()};
    }

    public static String sum(String sA, String sB) {
        if (isNegative(sA) && isNegative(sB)) return "-" + internalSum(getAbs(sA), getAbs(sB));
        if (isNegative(sA)) return internalSub(getAbs(sB), getAbs(sA));
        if (isNegative(sB)) return internalSub(getAbs(sA), getAbs(sB));
        return cleanNumber(internalSum(sA, sB));
    }

    private static String internalSum(String sA, String sB) {
        String[] aligned = alignStrings(sA, sB);
        sA = aligned[0]; sB = aligned[1];
        StringBuilder res = new StringBuilder();
        int carry = 0;
        for (int i = sA.length() - 1; i >= 0; i--) {
            if (sA.charAt(i) == decimalSeparator) { res.insert(0, decimalSeparator); continue; }
            int dSum = (sA.charAt(i) - '0') + (sB.charAt(i) - '0') + carry;
            carry = dSum / 10;
            res.insert(0, (char)((dSum % 10) + '0'));
        }
        if (carry > 0) res.insert(0, carry);
        return res.toString();
    }

    public static String sub(String sA, String sB) {
        if (isNegative(sB)) return sum(sA, getAbs(sB));
        if (isNegative(sA)) return "-" + internalSum(getAbs(sA), sB);
        return cleanNumber(internalSub(sA, sB));
    }

    private static String internalSub(String sA, String sB) {
        String[] aligned = alignStrings(sA, sB);
        sA = aligned[0]; sB = aligned[1];
        boolean neg = false;
        if (sA.compareTo(sB) < 0) { String tmp = sA; sA = sB; sB = tmp; neg = true; }
        StringBuilder res = new StringBuilder();
        int borrow = 0;
        for (int i = sA.length() - 1; i >= 0; i--) {
            if (sA.charAt(i) == decimalSeparator) { res.insert(0, decimalSeparator); continue; }
            int diff = (sA.charAt(i) - '0') - (sB.charAt(i) - '0') - borrow;
            if (diff < 0) { diff += 10; borrow = 1; } else borrow = 0;
            res.insert(0, (char)(diff + '0'));
        }
        String sRes = cleanNumber(res.toString());
        return neg ? "-" + sRes : sRes;
    }

    public static String multiply(String sA, String sB) {
        boolean resNeg = isNegative(sA) ^ isNegative(sB);
        sA = getAbs(sA); sB = getAbs(sB);
        int dotA = sA.indexOf(decimalSeparator);
        int decA = (dotA < 0) ? 0 : sA.length() - dotA - 1;
        String intA = sA.replace(String.valueOf(decimalSeparator), "");
        int dotB = sB.indexOf(decimalSeparator);
        int decB = (dotB < 0) ? 0 : sB.length() - dotB - 1;
        String intB = sB.replace(String.valueOf(decimalSeparator), "");
        int totalDecs = decA + decB;
        String finalRes = "0";
        for (int i = intB.length() - 1; i >= 0; i--) {
            int digitB = intB.charAt(i) - '0';
            if (digitB == 0) continue;
            StringBuilder currentRes = new StringBuilder();
            int carry = 0;
            for (int j = intA.length() - 1; j >= 0; j--) {
                int digitA = intA.charAt(j) - '0';
                int prod = (digitA * digitB) + carry;
                carry = prod / 10;
                currentRes.insert(0, (char)((prod % 10) + '0'));
            }
            if (carry > 0) currentRes.insert(0, carry);
            for(int k=0; k < (intB.length() - 1 - i); k++) currentRes.append('0');
            finalRes = internalSum(finalRes, currentRes.toString());
        }
        if (totalDecs > 0) {
            while (finalRes.length() <= totalDecs) finalRes = "0" + finalRes;
            finalRes = new StringBuilder(finalRes).insert(finalRes.length() - totalDecs, decimalSeparator).toString();
        }
        String result = resNeg ? "-" + finalRes : finalRes;
        return cleanNumber(result);
    }

    public static String divide(String sA, String sB) {
        if (cleanNumber(sB).equals("0")) return "0";
        boolean resNeg = isNegative(sA) ^ isNegative(sB);
        sA = getAbs(sA); sB = getAbs(sB);
        String[] aligned = alignStrings(sA, sB);
        String tA = cleanNumber(aligned[0].replace(String.valueOf(decimalSeparator), ""));
        String tB = cleanNumber(aligned[1].replace(String.valueOf(decimalSeparator), ""));
        StringBuilder quotient = new StringBuilder();
        StringBuilder current = new StringBuilder();
        int precision = 0;
        boolean hasDecimal = false;
        for (int i = 0; i < tA.length() + 10; i++) {
            if (i < tA.length()) current.append(tA.charAt(i));
            else {
                if (!hasDecimal) { if (quotient.length() == 0) quotient.append("0"); quotient.append(decimalSeparator); hasDecimal = true; }
                current.append('0'); precision++;
            }
            String sCurr = cleanNumber(current.toString());
            int count = 0;
            while (compareAbs(sCurr, tB) >= 0) { sCurr = internalSub(sCurr, tB); count++; }
            current = new StringBuilder(sCurr);
            if (quotient.length() > 0 || count > 0 || i == tA.length() - 1) quotient.append(count);
            if (i >= tA.length() - 1 && cleanNumber(current.toString()).equals("0")) break;
            if (precision >= 10) break;
        }
        String finalQuot = (resNeg && !quotient.toString().equals("0")) ? "-" + quotient : quotient.toString();
        return cleanNumber(finalQuot);
    }

    private static int compareAbs(String sA, String sB) {
        sA = cleanNumber(sA); sB = cleanNumber(sB);
        String[] aligned = alignStrings(sA, sB);
        return aligned[0].compareTo(aligned[1]);
    }
}
