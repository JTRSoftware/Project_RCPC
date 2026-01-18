using System;
using System.Text;
using System.Linq;

namespace JTRSoftware.Math
{
    public static class SMath
    {
        public static char DecimalSeparator = '.';

        private static string GetAbs(string sV) 
            => sV.StartsWith("-") ? sV.Substring(1) : sV;

        private static bool IsNegative(string sV) 
            => sV.StartsWith("-");

        public static string CleanNumber(string sV)
        {
            bool neg = IsNegative(sV);
            string val = GetAbs(sV);

            if (string.IsNullOrEmpty(val)) return "0";

            while (val.Length > 1 && val[0] == '0' && val[1] != DecimalSeparator)
                val = val.Substring(1);

            int dotPos = val.IndexOf(DecimalSeparator);
            if (dotPos >= 0)
            {
                while (val.Length > dotPos + 1 && val[val.Length - 1] == '0')
                    val = val.Substring(0, val.Length - 1);
                if (val[val.Length - 1] == DecimalSeparator)
                    val = val.Substring(0, val.Length - 1);
            }

            if (val == "" || val == DecimalSeparator.ToString()) val = "0";
            return (neg && val != "0") ? "-" + val : val;
        }

        private static void AlignStrings(ref string sA, ref string sB)
        {
            int dotA = sA.IndexOf(DecimalSeparator);
            int dotB = sB.IndexOf(DecimalSeparator);

            int decA = (dotA < 0) ? 0 : sA.Length - dotA - 1;
            int decB = (dotB < 0) ? 0 : sB.Length - dotB - 1;

            while (decA < decB)
            {
                if (dotA < 0) { sA += DecimalSeparator; dotA = sA.Length - 1; }
                sA += "0"; decA++;
            }
            while (decB < decA)
            {
                if (dotB < 0) { sB += DecimalSeparator; dotB = sB.Length - 1; }
                sB += "0"; decB++;
            }

            int intA = (dotA < 0) ? sA.Length : dotA;
            int intB = (dotB < 0) ? sB.Length : dotB;

            while (intA < intB) { sA = "0" + sA; intA++; }
            while (intB < intA) { sB = "0" + sB; intB++; }
        }

        public static string Sum(string sA, string sB)
        {
            if (IsNegative(sA) && IsNegative(sB))
                return "-" + InternalSum(GetAbs(sA), GetAbs(sB));
            if (IsNegative(sA))
                return InternalSub(GetAbs(sB), GetAbs(sA));
            if (IsNegative(sB))
                return InternalSub(GetAbs(sA), GetAbs(sB));

            return CleanNumber(InternalSum(sA, sB));
        }

        private static string InternalSum(string sA, string sB)
        {
            AlignStrings(ref sA, ref sB);
            var res = new StringBuilder();
            int carry = 0;

            for (int i = sA.Length - 1; i >= 0; i--)
            {
                if (sA[i] == DecimalSeparator)
                {
                    res.Insert(0, DecimalSeparator);
                    continue;
                }
                int digitSum = (sA[i] - '0') + (sB[i] - '0') + carry;
                carry = digitSum / 10;
                res.Insert(0, (digitSum % 10).ToString());
            }
            if (carry > 0) res.Insert(0, carry.ToString());
            return res.ToString();
        }

        public static string Sub(string sA, string sB)
        {
            if (IsNegative(sB)) return Sum(sA, GetAbs(sB));
            if (IsNegative(sA)) return "-" + InternalSum(GetAbs(sA), sB);
            return CleanNumber(InternalSub(sA, sB));
        }

        private static string InternalSub(string sA, string sB)
        {
            AlignStrings(ref sA, ref sB);
            bool neg = false;
            if (string.Compare(sA, sB) < 0)
            {
                string tmp = sA; sA = sB; sB = tmp; neg = true;
            }

            var res = new StringBuilder();
            int borrow = 0;

            for (int i = sA.Length - 1; i >= 0; i--)
            {
                if (sA[i] == DecimalSeparator)
                {
                    res.Insert(0, DecimalSeparator);
                    continue;
                }
                int diff = (sA[i] - '0') - (sB[i] - '0') - borrow;
                if (diff < 0) { diff += 10; borrow = 1; }
                else borrow = 0;
                res.Insert(0, diff.ToString());
            }
            string sRes = res.ToString();
            return neg ? "-" + sRes : sRes;
        }

        public static string Multiply(string sA, string sB)
        {
            bool resNeg = IsNegative(sA) ^ IsNegative(sB);
            sA = GetAbs(sA); sB = GetAbs(sB);

            int dotA = sA.IndexOf(DecimalSeparator);
            int decA = (dotA < 0) ? 0 : sA.Length - dotA - 1;
            string intA = sA.Replace(DecimalSeparator.ToString(), "");

            int dotB = sB.IndexOf(DecimalSeparator);
            int decB = (dotB < 0) ? 0 : sB.Length - dotB - 1;
            string intB = sB.Replace(DecimalSeparator.ToString(), "");

            int totalDecs = decA + decB;
            string finalRes = "0";

            for (int i = intB.Length - 1; i >= 0; i--)
            {
                int digitB = intB[i] - '0';
                if (digitB == 0) continue;
                var currentRes = new StringBuilder();
                int carry = 0;
                for (int j = intA.Length - 1; j >= 0; j--)
                {
                    int digitA = intA[j] - '0';
                    int prod = (digitA * digitB) + carry;
                    carry = prod / 10;
                    currentRes.Insert(0, (prod % 10).ToString());
                }
                if (carry > 0) currentRes.Insert(0, carry.ToString());
                currentRes.Append(new string('0', intB.Length - 1 - i));
                finalRes = InternalSum(finalRes, currentRes.ToString());
            }

            if (totalDecs > 0)
            {
                while (finalRes.Length <= totalDecs) finalRes = "0" + finalRes;
                finalRes = finalRes.Insert(finalRes.Length - totalDecs, DecimalSeparator.ToString());
            }

            string result = resNeg ? "-" + finalRes : finalRes;
            return CleanNumber(result);
        }

        public static string Divide(string sA, string sB)
        {
            if (CleanNumber(sB) == "0") return "0";
            bool resNeg = IsNegative(sA) ^ IsNegative(sB);
            sA = GetAbs(sA); sB = GetAbs(sB);

            string tA = sA, tB = sB;
            AlignStrings(ref tA, ref tB);
            tA = tA.Replace(DecimalSeparator.ToString(), "");
            tB = tB.Replace(DecimalSeparator.ToString(), "");
            tA = CleanNumber(tA); tB = CleanNumber(tB);

            string quotient = "";
            string current = "";
            int precision = 0;
            bool hasDecimal = false;

            for (int i = 0; i < tA.Length + 10; i++)
            {
                if (i < tA.Length) current += tA[i];
                else
                {
                    if (!hasDecimal)
                    {
                        if (quotient == "") quotient = "0";
                        quotient += DecimalSeparator;
                        hasDecimal = true;
                    }
                    current += "0";
                    precision++;
                }

                current = CleanNumber(current);
                int count = 0;
                while (CompareAbs(current, tB) >= 0)
                {
                    current = InternalSub(current, tB);
                    count++;
                }

                if (quotient != "" || count > 0 || i == tA.Length - 1)
                    quotient += count.ToString();

                if (i >= tA.Length - 1 && CleanNumber(current) == "0") break;
                if (precision >= 10) break;
            }

            string finalQuot = (resNeg && quotient != "0") ? "-" + quotient : quotient;
            return CleanNumber(finalQuot);
        }

        private static int CompareAbs(string sA, string sB)
        {
            sA = CleanNumber(sA); sB = CleanNumber(sB);
            AlignStrings(ref sA, ref sB);
            return string.Compare(sA, sB);
        }
    }
}
