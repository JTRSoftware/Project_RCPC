#include "sSwapMath.h"
#include <fstream>
#include <vector>
#include <algorithm>
#include <cstdio>

namespace sSwapMath {
    char DecimalSeparator = '.';
    int BufferSize = 1024 * 512;
    ProgressCallback OnProgress = nullptr;

    NumInfo GetNumInfo(const std::string& filePath) {
        NumInfo info = {0, 0, false, 0};
        std::ifstream fs(filePath, std::ios::binary | std::ios::ate);
        if (!fs.is_open()) return info;

        info.TotalLen = fs.tellg();
        fs.seekg(0, std::ios::beg);

        int64_t decPos = -1;
        std::vector<char> buffer(65536);
        while (fs) {
            fs.read(buffer.data(), buffer.size());
            std::streamsize readCount = fs.gcount();
            if (readCount <= 0) break;
            for (int i = 0; i < readCount; i++) {
                if (buffer[i] == DecimalSeparator) {
                    decPos = (int64_t)fs.tellg() - readCount + i;
                    break;
                }
            }
            if (decPos != -1) break;
        }

        if (decPos != -1) {
            info.HasDec = true;
            info.IntLen = decPos;
            info.DecLen = info.TotalLen - decPos - 1;
        } else {
            info.IntLen = info.TotalLen;
            info.DecLen = 0;
        }
        return info;
    }

    void ReverseFile(const std::string& source, const std::string& target) {
        std::ifstream fsIn(source, std::ios::binary | std::ios::ate);
        std::ofstream fsOut(target, std::ios::binary);
        int64_t fileSize = fsIn.tellg();
        std::vector<char> buffer(BufferSize);
        std::vector<char> revBuffer(BufferSize);
        int64_t totalBlocks = fileSize / BufferSize;
        int64_t remainder = fileSize % BufferSize;

        if (remainder > 0) {
            fsIn.seekg(fileSize - remainder, std::ios::beg);
            fsIn.read(buffer.data(), remainder);
            for (int64_t i = 0; i < remainder; i++) revBuffer[i] = buffer[remainder - 1 - i];
            fsOut.write(revBuffer.data(), remainder);
        }
        for (int64_t i = totalBlocks - 1; i >= 0; i--) {
            fsIn.seekg(i * BufferSize, std::ios::beg);
            fsIn.read(buffer.data(), BufferSize);
            for (int64_t j = 0; j < BufferSize; j++) revBuffer[j] = buffer[BufferSize - 1 - j];
            fsOut.write(revBuffer.data(), BufferSize);
        }
    }

    void CreateNormalizedFile(const std::string& source, const std::string& target, int64_t targetInt, int64_t targetDec) {
        NumInfo info = GetNumInfo(source);
        std::ifstream fsIn(source, std::ios::binary);
        std::ofstream fsOut(target, std::ios::binary);
        for (int64_t i = 0; i < (targetInt - info.IntLen); i++) fsOut.put('0');
        std::vector<char> buffer(BufferSize);
        int64_t remaining = info.IntLen;
        while (remaining > 0) {
            int64_t toRead = std::min((int64_t)BufferSize, remaining);
            fsIn.read(buffer.data(), toRead);
            fsOut.write(buffer.data(), fsIn.gcount());
            remaining -= fsIn.gcount();
        }
        fsOut.put(DecimalSeparator);
        if (info.HasDec) {
            fsIn.seekg(info.IntLen + 1, std::ios::beg);
            remaining = info.DecLen;
            while (remaining > 0) {
                int64_t toRead = std::min((int64_t)BufferSize, remaining);
                fsIn.read(buffer.data(), toRead);
                fsOut.write(buffer.data(), fsIn.gcount());
                remaining -= fsIn.gcount();
            }
        }
        for (int64_t i = 0; i < (targetDec - info.DecLen); i++) fsOut.put('0');
    }

    int SwapCompare(const std::string& fileA, const std::string& fileB) {
        NumInfo infoA = GetNumInfo(fileA);
        NumInfo infoB = GetNumInfo(fileB);
        if (infoA.IntLen > infoB.IntLen) return 1;
        if (infoA.IntLen < infoB.IntLen) return -1;
        std::ifstream fsA(fileA, std::ios::binary);
        std::ifstream fsB(fileB, std::ios::binary);
        for (int64_t i = 0; i < infoA.IntLen; i++) {
            char ca = fsA.get(), cb = fsB.get();
            if (ca > cb) return 1;
            if (ca < cb) return -1;
        }
        int64_t maxDec = std::max(infoA.DecLen, infoB.DecLen);
        for (int64_t i = 1; i <= maxDec; i++) {
            char ca = '0', cb = '0';
            if (i <= infoA.DecLen) { fsA.seekg(infoA.IntLen + i, std::ios::beg); ca = fsA.get(); }
            if (i <= infoB.DecLen) { fsB.seekg(infoB.IntLen + i, std::ios::beg); cb = fsB.get(); }
            if (ca > cb) return 1;
            if (ca < cb) return -1;
        }
        return 0;
    }

    void SwapSum(const std::string& fileA, const std::string& fileB, const std::string& fileRes) {
        NumInfo infoA = GetNumInfo(fileA); NumInfo infoB = GetNumInfo(fileB);
        int64_t maxInt = std::max(infoA.IntLen, infoB.IntLen);
        int64_t maxDec = std::max(infoA.DecLen, infoB.DecLen);
        std::string nA = fileA + ".n", nB = fileB + ".n", tR = fileRes + ".t";
        CreateNormalizedFile(fileA, nA, maxInt, maxDec);
        CreateNormalizedFile(fileB, nB, maxInt, maxDec);
        std::ifstream fsA(nA, std::ios::binary); std::ifstream fsB(nB, std::ios::binary);
        std::ofstream fsR(tR, std::ios::binary);
        int carry = 0; fsA.seekg(0, std::ios::end); int64_t len = fsA.tellg();
        for (int64_t i = len - 1; i >= 0; i--) {
            fsA.seekg(i, std::ios::beg); fsB.seekg(i, std::ios::beg);
            char ca = fsA.get(), cb = fsB.get();
            if (ca == DecimalSeparator) { fsR.put(DecimalSeparator); continue; }
            int sum = (ca - '0') + (cb - '0') + carry;
            carry = sum / 10; fsR.put((char)((sum % 10) + '0'));
        }
        if (carry > 0) fsR.put((char)(carry + '0'));
        fsA.close(); fsB.close(); fsR.close();
        ReverseFile(tR, fileRes); std::remove(nA.c_str()); std::remove(nB.c_str()); std::remove(tR.c_str());
    }

    void SwapSub(const std::string& fileA, const std::string& fileB, const std::string& fileRes) {
        NumInfo infoA = GetNumInfo(fileA); NumInfo infoB = GetNumInfo(fileB);
        int64_t maxInt = std::max(infoA.IntLen, infoB.IntLen);
        int64_t maxDec = std::max(infoA.DecLen, infoB.DecLen);
        std::string nA = fileA + ".n", nB = fileB + ".n", tR = fileRes + ".t";
        CreateNormalizedFile(fileA, nA, maxInt, maxDec);
        CreateNormalizedFile(fileB, nB, maxInt, maxDec);
        std::ifstream fsA(nA, std::ios::binary); std::ifstream fsB(nB, std::ios::binary);
        std::ofstream fsR(tR, std::ios::binary);
        int borrow = 0; fsA.seekg(0, std::ios::end); int64_t len = fsA.tellg();
        for (int64_t i = len - 1; i >= 0; i--) {
            fsA.seekg(i, std::ios::beg); fsB.seekg(i, std::ios::beg);
            char ca = fsA.get(), cb = fsB.get();
            if (ca == DecimalSeparator) { fsR.put(DecimalSeparator); continue; }
            int diff = (ca - '0') - (cb - '0') - borrow;
            if (diff < 0) { diff += 10; borrow = 1; } else borrow = 0;
            fsR.put((char)(diff + '0'));
        }
        fsA.close(); fsB.close(); fsR.close();
        ReverseFile(tR, fileRes); std::remove(nA.c_str()); std::remove(nB.c_str()); std::remove(tR.c_str());
    }

    void SwapMultiplyDigit(const std::string& fileIn, const std::string& fileRes, int digit, int64_t shift) {
        std::string tR = fileRes + ".t"; std::ifstream fsIn(fileIn, std::ios::binary);
        std::ofstream fsOut(tR, std::ios::binary);
        int carry = 0; for (int64_t i = 0; i < shift; i++) fsOut.put('0');
        fsIn.seekg(0, std::ios::end); int64_t len = fsIn.tellg();
        for (int64_t i = len - 1; i >= 0; i--) {
            fsIn.seekg(i, std::ios::beg); char ci = fsIn.get();
            if (ci == DecimalSeparator) continue;
            int prod = (ci - '0') * digit + carry;
            carry = prod / 10; fsOut.put((char)((prod % 10) + '0'));
        }
        if (carry > 0) fsOut.put((char)(carry + '0'));
        fsIn.close(); fsOut.close(); ReverseFile(tR, fileRes); std::remove(tR.c_str());
    }

    void SwapMultiply(const std::string& fileA, const std::string& fileB, const std::string& fileRes) {
        std::string acc = fileRes + ".acc"; std::ofstream fs(acc); fs << "0"; fs.close();
        std::ifstream fsB(fileB, std::ios::binary); fsB.seekg(0, std::ios::end);
        int64_t lenB = fsB.tellg(); int64_t shift = 0;
        for (int64_t i = lenB - 1; i >= 0; i--) {
            fsB.seekg(i, std::ios::beg); char bc = fsB.get();
            if (bc == DecimalSeparator) continue;
            int digit = bc - '0';
            if (digit > 0) {
                std::string tD = fileRes + ".d", tN = acc + ".n";
                SwapMultiplyDigit(fileA, tD, digit, shift); SwapSum(acc, tD, tN);
                std::remove(acc.c_str()); std::remove(tD.c_str()); std::rename(tN.c_str(), acc.c_str());
            }
            shift++;
        }
        std::remove(fileRes.c_str()); std::rename(acc.c_str(), fileRes.c_str());
    }

    void SwapDivide(const std::string& fileA, const std::string& fileB, const std::string& fileRes) {
        std::string curr = fileRes + ".c", quot = fileRes + ".q";
        std::ofstream fsc(curr); fsc << "0"; fsc.close();
        std::ofstream fsq(quot); fsq.close();
        std::ifstream fsA(fileA, std::ios::binary); fsA.seekg(0, std::ios::end);
        int64_t lenA = fsA.tellg();
        for (int64_t i = 0; i < lenA; i++) {
            fsA.seekg(i, std::ios::beg); char ca = fsA.get();
            if (ca == DecimalSeparator) continue;
            std::string tC = curr + ".t";
            std::ifstream fsi(curr); std::string content; std::getline(fsi, content); fsi.close();
            std::ofstream fso(tC); fso << (content == "0" ? std::string(1, ca) : content + ca); fso.close();
            std::remove(curr.c_str()); std::rename(tC.c_str(), curr.c_str());
            int count = 0;
            while (SwapCompare(curr, fileB) >= 0) {
                std::string tS = curr + ".s"; SwapSub(curr, fileB, tS);
                std::remove(curr.c_str()); std::rename(tS.c_str(), curr.c_str()); count++;
            }
            std::ofstream fsa(quot, std::ios::app); fsa << count; fsa.close();
        }
        std::remove(fileRes.c_str()); std::rename(quot.c_str(), fileRes.c_str()); std::remove(curr.c_str());
    }
}
