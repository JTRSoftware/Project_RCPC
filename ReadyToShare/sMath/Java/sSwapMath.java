package jtrsoftware.math;

import java.io.*;
import java.util.Collections;

public class SSwapMath {
    public static char decimalSeparator = '.';
    public static int bufferSize = 1024 * 512;

    public interface ProgressCallback {
        void onProgress(long current, long total);
    }
    public static ProgressCallback onProgress = null;

    public static class NumInfo {
        public long intLen, decLen, totalLen;
        public boolean hasDec;
    }

    public static NumInfo getNumInfo(String filePath) throws IOException {
        NumInfo info = new NumInfo();
        File f = new File(filePath);
        if (!f.exists()) return info;
        info.totalLen = f.length();
        long decPos = -1;
        try (RandomAccessFile raf = new RandomAccessFile(f, "r")) {
            byte[] buffer = new byte[65536];
            int read;
            while ((read = raf.read(buffer)) > 0) {
                for (int i = 0; i < read; i++) {
                    if ((char)buffer[i] == decimalSeparator) {
                        decPos = raf.getFilePointer() - read + i;
                        break;
                    }
                }
                if (decPos != -1) break;
            }
        }
        if (decPos != -1) {
            info.hasDec = true;
            info.intLen = decPos;
            info.decLen = info.totalLen - decPos - 1;
        } else {
            info.intLen = info.totalLen;
            info.decLen = 0;
        }
        return info;
    }

    public static void reverseFile(String source, String target) throws IOException {
        File fIn = new File(source);
        long fileSize = fIn.length();
        try (RandomAccessFile raf = new RandomAccessFile(fIn, "r");
             OutputStream out = new BufferedOutputStream(new FileOutputStream(target))) {
            byte[] buffer = new byte[bufferSize];
            byte[] revBuffer = new byte[bufferSize];
            long totalBlocks = fileSize / bufferSize;
            int remainder = (int)(fileSize % bufferSize);
            if (remainder > 0) {
                raf.seek(fileSize - remainder);
                raf.read(buffer, 0, remainder);
                for (int i = 0; i < remainder; i++) revBuffer[i] = buffer[remainder - 1 - i];
                out.write(revBuffer, 0, remainder);
            }
            for (long i = totalBlocks - 1; i >= 0; i--) {
                raf.seek(i * bufferSize);
                raf.read(buffer, 0, bufferSize);
                for (int j = 0; j < bufferSize; j++) revBuffer[j] = buffer[bufferSize - 1 - j];
                out.write(revBuffer, 0, bufferSize);
            }
        }
    }

    public static void createNormalizedFile(String source, String target, long targetInt, long targetDec) throws IOException {
        NumInfo info = getNumInfo(source);
        try (RandomAccessFile rafIn = new RandomAccessFile(source, "r");
             OutputStream out = new BufferedOutputStream(new FileOutputStream(target))) {
            for (long i = 0; i < (targetInt - info.intLen); i++) out.write('0');
            byte[] buffer = new byte[65536];
            long remaining = info.intLen;
            while (remaining > 0) {
                int toRead = (int)Math.min(buffer.length, remaining);
                int read = rafIn.read(buffer, 0, toRead);
                out.write(buffer, 0, read);
                remaining -= read;
            }
            out.write(decimalSeparator);
            if (info.hasDec) {
                rafIn.seek(info.intLen + 1);
                remaining = info.decLen;
                while (remaining > 0) {
                    int toRead = (int)Math.min(buffer.length, remaining);
                    int read = rafIn.read(buffer, 0, toRead);
                    out.write(buffer, 0, read);
                    remaining -= read;
                }
            }
            for (long i = 0; i < (targetDec - info.decLen); i++) out.write('0');
        }
    }

    public static int swapCompare(String fileA, String fileB) throws IOException {
        NumInfo infoA = getNumInfo(fileA);
        NumInfo infoB = getNumInfo(fileB);
        if (infoA.intLen > infoB.intLen) return 1;
        if (infoA.intLen < infoB.intLen) return -1;
        try (RandomAccessFile rafA = new RandomAccessFile(fileA, "r");
             RandomAccessFile rafB = new RandomAccessFile(fileB, "r")) {
            for (long i = 0; i < infoA.intLen; i++) {
                int ca = rafA.read(), cb = rafB.read();
                if (ca > cb) return 1;
                if (ca < cb) return -1;
            }
            long maxDec = Math.max(infoA.decLen, infoB.decLen);
            for (long i = 1; i <= maxDec; i++) {
                int ca = '0', cb = '0';
                if (i <= infoA.decLen) { rafA.seek(infoA.intLen + i); ca = rafA.read(); }
                if (i <= infoB.decLen) { rafB.seek(infoB.intLen + i); cb = rafB.read(); }
                if (ca > cb) return 1;
                if (ca < cb) return -1;
            }
        }
        return 0;
    }

    public static void swapSum(String fileA, String fileB, String fileRes) throws IOException {
        NumInfo infoA = getNumInfo(fileA); NumInfo infoB = getNumInfo(fileB);
        long maxInt = Math.max(infoA.intLen, infoB.intLen);
        long maxDec = Math.max(infoA.decLen, infoB.decLen);
        String nA = fileA + ".n", nB = fileB + ".n", tR = fileRes + ".t";
        createNormalizedFile(fileA, nA, maxInt, maxDec);
        createNormalizedFile(fileB, nB, maxInt, maxDec);
        try (RandomAccessFile rafA = new RandomAccessFile(nA, "r");
             RandomAccessFile rafB = new RandomAccessFile(nB, "r");
             OutputStream fsRes = new BufferedOutputStream(new FileOutputStream(tR))) {
            int carry = 0; long total = rafA.length();
            for (long i = total - 1; i >= 0; i--) {
                rafA.seek(i); rafB.seek(i);
                int ca = rafA.read(), cb = rafB.read();
                if ((char)ca == decimalSeparator) { fsRes.write(decimalSeparator); continue; }
                int sum = (ca - '0') + (cb - '0') + carry;
                carry = sum / 10;
                fsRes.write((sum % 10) + '0');
            }
            if (carry > 0) fsRes.write(carry + '0');
        }
        reverseFile(tR, fileRes);
        new File(nA).delete(); new File(nB).delete(); new File(tR).delete();
    }

    public static void swapSub(String fileA, String fileB, String fileRes) throws IOException {
        NumInfo infoA = getNumInfo(fileA); NumInfo infoB = getNumInfo(fileB);
        long maxInt = Math.max(infoA.intLen, infoB.intLen);
        long maxDec = Math.max(infoA.decLen, infoB.decLen);
        String nA = fileA + ".n", nB = fileB + ".n", tR = fileRes + ".t";
        createNormalizedFile(fileA, nA, maxInt, maxDec);
        createNormalizedFile(fileB, nB, maxInt, maxDec);
        try (RandomAccessFile rafA = new RandomAccessFile(nA, "r");
             RandomAccessFile rafB = new RandomAccessFile(nB, "r");
             OutputStream fsRes = new BufferedOutputStream(new FileOutputStream(tR))) {
            int borrow = 0; long total = rafA.length();
            for (long i = total - 1; i >= 0; i--) {
                rafA.seek(i); rafB.seek(i);
                int ca = rafA.read(), cb = rafB.read();
                if ((char)ca == decimalSeparator) { fsRes.write(decimalSeparator); continue; }
                int diff = (ca - '0') - (cb - '0') - borrow;
                if (diff < 0) { diff += 10; borrow = 1; } else borrow = 0;
                fsRes.write(diff + '0');
            }
        }
        reverseFile(tR, fileRes);
        new File(nA).delete(); new File(nB).delete(); new File(tR).delete();
    }

    public static void swapMultiplyDigit(String fileIn, String fileRes, int digit, long shift) throws IOException {
        String tR = fileRes + ".t";
        try (RandomAccessFile rafIn = new RandomAccessFile(fileIn, "r");
             OutputStream out = new BufferedOutputStream(new FileOutputStream(tR))) {
            int carry = 0; for (int i = 0; i < shift; i++) out.write('0');
            long size = rafIn.length();
            for (long i = size - 1; i >= 0; i--) {
                rafIn.seek(i);
                int ci = rafIn.read(); if ((char)ci == decimalSeparator) continue;
                int prod = (ci - '0') * digit + carry;
                carry = prod / 10; out.write((prod % 10) + '0');
            }
            if (carry > 0) out.write(carry + '0');
        }
        reverseFile(tR, fileRes); new File(tR).delete();
    }

    public static void swapMultiply(String fileA, String fileB, String fileRes) throws IOException {
        String acc = fileRes + ".acc";
        try (PrintWriter pw = new PrintWriter(acc)) { pw.print("0"); }
        try (RandomAccessFile rafB = new RandomAccessFile(fileB, "r")) {
            long sizeB = rafB.length(); long shift = 0;
            for (long i = sizeB - 1; i >= 0; i--) {
                rafB.seek(i); int bc = rafB.read(); if ((char)bc == decimalSeparator) continue;
                int digit = bc - '0';
                if (digit > 0) {
                    String tD = fileRes + ".d", tN = acc + ".n";
                    swapMultiplyDigit(fileA, tD, digit, shift);
                    swapSum(acc, tD, tN);
                    new File(acc).delete(); new File(tD).delete(); new File(tN).renameTo(new File(acc));
                }
                shift++;
            }
        }
        File target = new File(fileRes); if (target.exists()) target.delete();
        new File(acc).renameTo(target);
    }

    public static void swapDivide(String fileA, String fileB, String fileRes) throws IOException {
        String curr = fileRes + ".c", quot = fileRes + ".q";
        try (PrintWriter pw = new PrintWriter(curr)) { pw.print("0"); }
        try (PrintWriter pw = new PrintWriter(quot)) { pw.print(""); }
        try (RandomAccessFile fsA = new RandomAccessFile(fileA, "r");
             OutputStream outQ = new BufferedOutputStream(new FileOutputStream(quot))) {
            long lenA = fsA.length();
            for (long i = 0; i < lenA; i++) {
                fsA.seek(i); int ca = fsA.read(); if ((char)ca == decimalSeparator) continue;
                String tC = curr + ".t";
                String content;
                try (BufferedReader br = new BufferedReader(new FileReader(curr))) { content = br.readLine(); }
                if (content == null) content = "0";
                try (PrintWriter pw = new PrintWriter(tC)) { pw.print(content.equals("0") ? (char)ca : content + (char)ca); }
                new File(curr).delete(); new File(tC).renameTo(new File(curr));
                int count = 0;
                while (swapCompare(curr, fileB) >= 0) {
                    String tS = curr + ".s"; swapSub(curr, fileB, tS);
                    new File(curr).delete(); new File(tS).renameTo(new File(curr));
                    count++;
                }
                outQ.write(count + '0');
            }
        }
        File target = new File(fileRes); if (target.exists()) target.delete();
        new File(quot).renameTo(target); new File(curr).delete();
    }
}
