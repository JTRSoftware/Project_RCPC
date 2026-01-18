#include "sMath.h"
#include <algorithm>
#include <vector>

namespace sMath {
    char DecimalSeparator = '.';

    bool IsNegative(const std::string& sV) {
        return !sV.empty() && sV[0] == '-';
    }

    std::string GetAbs(const std::string& sV) {
        if (IsNegative(sV)) return sV.substr(1);
        return sV;
    }

    std::string CleanNumber(std::string sV) {
        bool neg = IsNegative(sV);
        std::string val = GetAbs(sV);
        if (val.empty()) return "0";

        while (val.length() > 1 && val[0] == '0' && val[1] != DecimalSeparator)
            val.erase(0, 1);

        size_t dotPos = val.find(DecimalSeparator);
        if (dotPos != std::string::npos) {
            while (val.length() > dotPos + 1 && val.back() == '0')
                val.pop_back();
            if (val.back() == DecimalSeparator)
                val.pop_back();
        }

        if (val.empty() || val == std::string(1, DecimalSeparator)) val = "0";
        return (neg && val != "0") ? "-" + val : val;
    }

    void AlignStrings(std::string& sA, std::string& sB) {
        size_t dotA = sA.find(DecimalSeparator);
        size_t dotB = sB.find(DecimalSeparator);

        size_t decA = (dotA == std::string::npos) ? 0 : sA.length() - dotA - 1;
        size_t decB = (dotB == std::string::npos) ? 0 : sB.length() - dotB - 1;

        while (decA < decB) {
            if (dotA == std::string::npos) { sA += DecimalSeparator; dotA = sA.length() - 1; }
            sA += '0'; decA++;
        }
        while (decB < decA) {
            if (dotB == std::string::npos) { sB += DecimalSeparator; dotB = sB.length() - 1; }
            sB += '0'; decB++;
        }

        size_t intA = (dotA == std::string::npos) ? sA.length() : dotA;
        size_t intB = (dotB == std::string::npos) ? sB.length() : dotB;

        while (intA < intB) { sA = "0" + sA; intA++; }
        while (intB < intA) { sB = "0" + sB; intB++; }
    }

    std::string InternalSum(std::string sA, std::string sB) {
        AlignStrings(sA, sB);
        std::string res = "";
        int carry = 0;
        for (int i = sA.length() - 1; i >= 0; i--) {
            if (sA[i] == DecimalSeparator) {
                res = DecimalSeparator + res;
                continue;
            }
            int digitSum = (sA[i] - '0') + (sB[i] - '0') + carry;
            carry = digitSum / 10;
            res = std::to_string(digitSum % 10) + res;
        }
        if (carry > 0) res = std::to_string(carry) + res;
        return res;
    }

    std::string InternalSub(std::string sA, std::string sB) {
        AlignStrings(sA, sB);
        bool neg = false;
        if (sA < sB) { std::swap(sA, sB); neg = true; }
        std::string res = "";
        int borrow = 0;
        for (int i = sA.length() - 1; i >= 0; i--) {
            if (sA[i] == DecimalSeparator) {
                res = DecimalSeparator + res;
                continue;
            }
            int diff = (sA[i] - '0') - (sB[i] - '0') - borrow;
            if (diff < 0) { diff += 10; borrow = 1; }
            else borrow = 0;
            res = std::to_string(diff) + res;
        }
        std::string sRes = CleanNumber(res);
        return neg ? "-" + sRes : sRes;
    }

    std::string Sum(std::string sA, std::string sB) {
        if (IsNegative(sA) && IsNegative(sB))
            return "-" + InternalSum(GetAbs(sA), GetAbs(sB));
        if (IsNegative(sA)) return InternalSub(GetAbs(sB), GetAbs(sA));
        if (IsNegative(sB)) return InternalSub(GetAbs(sA), GetAbs(sB));
        return CleanNumber(InternalSum(sA, sB));
    }

    std::string Sub(std::string sA, std::string sB) {
        if (IsNegative(sB)) return Sum(sA, GetAbs(sB));
        if (IsNegative(sA)) return "-" + InternalSum(GetAbs(sA), sB);
        return CleanNumber(InternalSub(sA, sB));
    }

    std::string Multiply(std::string sA, std::string sB) {
        bool resNeg = IsNegative(sA) ^ IsNegative(sB);
        sA = GetAbs(sA); sB = GetAbs(sB);

        size_t dotA = sA.find(DecimalSeparator);
        size_t decA = (dotA == std::string::npos) ? 0 : sA.length() - dotA - 1;
        std::string intA = sA;
        intA.erase(std::remove(intA.begin(), intA.end(), DecimalSeparator), intA.end());

        size_t dotB = sB.find(DecimalSeparator);
        size_t decB = (dotB == std::string::npos) ? 0 : sB.length() - dotB - 1;
        std::string intB = sB;
        intB.erase(std::remove(intB.begin(), intB.end(), DecimalSeparator), intB.end());

        int totalDecs = (int)(decA + decB);
        std::string finalRes = "0";

        for (int i = intB.length() - 1; i >= 0; i--) {
            int digitB = intB[i] - '0';
            if (digitB == 0) continue;
            std::string currentRes = "";
            int carry = 0;
            for (int j = intA.length() - 1; j >= 0; j--) {
                int digitA = intA[j] - '0';
                int prod = (digitA * digitB) + carry;
                carry = prod / 10;
                currentRes = std::to_string(prod % 10) + currentRes;
            }
            if (carry > 0) currentRes = std::to_string(carry) + currentRes;
            for(int k=0; k < (int)intB.length() - 1 - i; k++) currentRes += '0';
            finalRes = InternalSum(finalRes, currentRes);
        }

        if (totalDecs > 0) {
            while (finalRes.length() <= (size_t)totalDecs) finalRes = "0" + finalRes;
            finalRes.insert(finalRes.length() - totalDecs, 1, DecimalSeparator);
        }

        std::string result = resNeg ? "-" + finalRes : finalRes;
        return CleanNumber(result);
    }

    int CompareAbs(std::string sA, std::string sB) {
        sA = CleanNumber(sA); sB = CleanNumber(sB);
        AlignStrings(sA, sB);
        if (sA == sB) return 0;
        return (sA > sB) ? 1 : -1;
    }

    std::string Divide(std::string sA, std::string sB) {
        if (CleanNumber(sB) == "0") return "0";
        bool resNeg = IsNegative(sA) ^ IsNegative(sB);
        sA = GetAbs(sA); sB = GetAbs(sB);

        std::string tA = sA, tB = sB;
        AlignStrings(tA, tB);
        tA.erase(std::remove(tA.begin(), tA.end(), DecimalSeparator), tA.end());
        tB.erase(std::remove(tB.begin(), tB.end(), DecimalSeparator), tB.end());
        tA = CleanNumber(tA); tB = CleanNumber(tB);

        std::string quotient = "";
        std::string current = "";
        int precision = 0;
        bool hasDecimal = false;

        for (int i = 0; i < (int)tA.length() + 10; i++) {
            if (i < (int)tA.length()) current += tA[i];
            else {
                if (!hasDecimal) {
                    if (quotient == "") quotient = "0";
                    quotient += DecimalSeparator;
                    hasDecimal = true;
                }
                current += '0';
                precision++;
            }

            current = CleanNumber(current);
            int count = 0;
            while (CompareAbs(current, tB) >= 0) {
                current = InternalSub(current, tB);
                count++;
            }

            if (quotient != "" || count > 0 || i == (int)tA.length() - 1)
                quotient += std::to_string(count);

            if (i >= (int)tA.length() - 1 && CleanNumber(current) == "0") break;
            if (precision >= 10) break;
        }

        std::string finalQuot = (resNeg && quotient != "0") ? "-" + quotient : quotient;
        return CleanNumber(finalQuot);
    }
}
