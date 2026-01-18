using System;
using System.IO;
using System.Linq;

namespace JTRSoftware.Math
{
    public static class SSwapMath
    {
        public static char DecimalSeparator = '.';
        public static int BufferSize = 1024 * 512; 

        public delegate void ProgressHandler(long current, long total);
        public static event ProgressHandler OnProgress;

        public struct NumInfo
        {
            public long IntLen;
            public long DecLen;
            public bool HasDec;
            public long TotalLen;
        }

        public static NumInfo GetNumInfo(string filePath)
        {
            var info = new NumInfo { IntLen = 0, DecLen = 0, HasDec = false, TotalLen = 0 };
            if (!File.Exists(filePath)) return info;

            using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read))
            {
                info.TotalLen = fs.Length;
                long decPos = -1;
                byte[] buffer = new byte[65536];
                int read;

                while ((read = fs.Read(buffer, 0, buffer.Length)) > 0)
                {
                    for (int i = 0; i < read; i++)
                    {
                        if ((char)buffer[i] == DecimalSeparator)
                        {
                            decPos = fs.Position - (read - i);
                            break;
                        }
                    }
                    if (decPos != -1) break;
                }

                if (decPos != -1)
                {
                    info.HasDec = true;
                    info.IntLen = decPos;
                    info.DecLen = fs.Length - decPos - 1;
                }
                else
                {
                    info.IntLen = fs.Length;
                    info.DecLen = 0;
                }
            }
            return info;
        }

        public static void ReverseFile(string source, string target)
        {
            using (var fsIn = new FileStream(source, FileMode.Open, FileAccess.Read))
            using (var fsOut = new FileStream(target, FileMode.Create, FileAccess.Write))
            {
                byte[] buffer = new byte[BufferSize];
                byte[] revBuffer = new byte[BufferSize];
                long totalBlocks = fsIn.Length / BufferSize;
                int remainder = (int)(fsIn.Length % BufferSize);

                if (remainder > 0)
                {
                    fsIn.Position = fsIn.Length - remainder;
                    fsIn.Read(buffer, 0, remainder);
                    for (int i = 0; i < remainder; i++)
                        revBuffer[i] = buffer[remainder - 1 - i];
                    fsOut.Write(revBuffer, 0, remainder);
                }

                for (long i = totalBlocks - 1; i >= 0; i--)
                {
                    fsIn.Position = i * BufferSize;
                    fsIn.Read(buffer, 0, BufferSize);
                    for (int j = 0; j < BufferSize; j++)
                        revBuffer[j] = buffer[BufferSize - 1 - j];
                    fsOut.Write(revBuffer, 0, BufferSize);
                }
            }
        }

        public static void CreateNormalizedFile(string source, string target, long targetInt, long targetDec)
        {
            var info = GetNumInfo(source);
            using (var fsIn = new FileStream(source, FileMode.Open, FileAccess.Read))
            using (var fsOut = new FileStream(target, FileMode.Create, FileAccess.Write))
            {
                for (long i = 0; i < (targetInt - info.IntLen); i++)
                    fsOut.WriteByte((byte)'0');

                byte[] buffer = new byte[BufferSize];
                long remaining = info.IntLen;
                while (remaining > 0)
                {
                    int toRead = (int)Math.Min(BufferSize, remaining);
                    int read = fsIn.Read(buffer, 0, toRead);
                    fsOut.Write(buffer, 0, read);
                    remaining -= read;
                }

                fsOut.WriteByte((byte)DecimalSeparator);

                if (info.HasDec)
                {
                    fsIn.Position = info.IntLen + 1;
                    remaining = info.DecLen;
                    while (remaining > 0)
                    {
                        int toRead = (int)Math.Min(BufferSize, remaining);
                        int read = fsIn.Read(buffer, 0, toRead);
                        fsOut.Write(buffer, 0, read);
                        remaining -= read;
                    }
                }

                for (long i = 0; i < (targetDec - info.DecLen); i++)
                    fsOut.WriteByte((byte)'0');
            }
        }

        public static int CompareAbs(string fileA, string fileB)
        {
            var infoA = GetNumInfo(fileA);
            var infoB = GetNumInfo(fileB);
            
            // Comparar parte inteira (ignorar zeros à esquerda)
            if (infoA.IntLen > infoB.IntLen) return 1;
            if (infoA.IntLen < infoB.IntLen) return -1;

            using (var fsA = new FileStream(fileA, FileMode.Open, FileAccess.Read))
            using (var fsB = new FileStream(fileB, FileMode.Open, FileAccess.Read))
            {
                for (long i = 0; i < infoA.IntLen; i++)
                {
                    int ca = fsA.ReadByte();
                    int cb = fsB.ReadByte();
                    if (ca > cb) return 1;
                    if (ca < cb) return -1;
                }
                long maxDec = Math.Max(infoA.DecLen, infoB.DecLen);
                for (long i = 1; i <= maxDec; i++)
                {
                    int ca = '0', cb = '0';
                    if (i <= infoA.DecLen) { fsA.Position = infoA.IntLen + i; ca = fsA.ReadByte(); }
                    if (i <= infoB.DecLen) { fsB.Position = infoB.IntLen + i; cb = fsB.ReadByte(); }
                    if (ca > cb) return 1;
                    if (ca < cb) return -1;
                }
            }
            return 0;
        }

        public static void SwapSum(string fileA, string fileB, string fileRes)
        {
            var infoA = GetNumInfo(fileA);
            var infoB = GetNumInfo(fileB);
            long maxInt = Math.Max(infoA.IntLen, infoB.IntLen);
            long maxDec = Math.Max(infoA.DecLen, infoB.DecLen);
            string normA = fileA + ".nrm", normB = fileB + ".nrm", tmpRes = fileRes + ".tmp";
            CreateNormalizedFile(fileA, normA, maxInt, maxDec);
            CreateNormalizedFile(fileB, normB, maxInt, maxDec);

            using (var fsA = new FileStream(normA, FileMode.Open, FileAccess.Read))
            using (var fsB = new FileStream(normB, FileMode.Open, FileAccess.Read))
            using (var fsRes = new FileStream(tmpRes, FileMode.Create, FileAccess.Write))
            {
                int carry = 0; long len = fsA.Length;
                for (long i = len - 1; i >= 0; i--)
                {
                    fsA.Position = i; fsB.Position = i;
                    int ca = fsA.ReadByte(), cb = fsB.ReadByte();
                    if ((char)ca == DecimalSeparator) { fsRes.WriteByte((byte)DecimalSeparator); continue; }
                    int sum = (ca - '0') + (cb - '0') + carry;
                    carry = sum / 10;
                    fsRes.WriteByte((byte)((sum % 10) + '0'));
                }
                if (carry > 0) fsRes.WriteByte((byte)(carry + '0'));
            }
            ReverseFile(tmpRes, fileRes);
            File.Delete(normA); File.Delete(normB); File.Delete(tmpRes);
        }

        public static void SwapSub(string fileA, string fileB, string fileRes)
        {
            var infoA = GetNumInfo(fileA);
            var infoB = GetNumInfo(fileB);
            long maxInt = Math.Max(infoA.IntLen, infoB.IntLen);
            long maxDec = Math.Max(infoA.DecLen, infoB.DecLen);
            string normA = fileA + ".nrm", normB = fileB + ".nrm", tmpRes = fileRes + ".tmp";
            CreateNormalizedFile(fileA, normA, maxInt, maxDec);
            CreateNormalizedFile(fileB, normB, maxInt, maxDec);

            using (var fsA = new FileStream(normA, FileMode.Open, FileAccess.Read))
            using (var fsB = new FileStream(normB, FileMode.Open, FileAccess.Read))
            using (var fsRes = new FileStream(tmpRes, FileMode.Create, FileAccess.Write))
            {
                int brw = 0; long len = fsA.Length;
                for (long i = len - 1; i >= 0; i--)
                {
                    fsA.Position = i; fsB.Position = i;
                    int ca = fsA.ReadByte(), cb = fsB.ReadByte();
                    if ((char)ca == DecimalSeparator) { fsRes.WriteByte((byte)DecimalSeparator); continue; }
                    int diff = (ca - '0') - (cb - '0') - brw;
                    if (diff < 0) { diff += 10; brw = 1; } else brw = 0;
                    fsRes.WriteByte((byte)(diff + '0'));
                }
            }
            ReverseFile(tmpRes, fileRes);
            File.Delete(normA); File.Delete(normB); File.Delete(tempRes);
        }

        public static void SwapMultiplyDigit(string fileIn, string fileRes, int digit, long shift)
        {
            string tmp = fileRes + ".t";
            using (var fsIn = new FileStream(fileIn, FileMode.Open, FileAccess.Read))
            using (var fsRes = new FileStream(tmp, FileMode.Create, FileAccess.Write))
            {
                int cry = 0;
                for (int i = 0; i < shift; i++) fsRes.WriteByte((byte)'0');
                for (long i = fsIn.Length - 1; i >= 0; i--)
                {
                    fsIn.Position = i; int ci = fsIn.ReadByte();
                    if ((char)ci == DecimalSeparator) continue;
                    int prd = (ci - '0') * digit + cry;
                    cry = prd / 10;
                    fsRes.WriteByte((byte)((prd % 10) + '0'));
                }
                if (cry > 0) fsRes.WriteByte((byte)(cry + '0'));
            }
            ReverseFile(tmp, fileRes); File.Delete(tmp);
        }

        public static void SwapMultiply(string fileA, string fileB, string fileRes)
        {
            string acc = fileRes + ".acc"; File.WriteAllText(acc, "0");
            using (var fsB = new FileStream(fileB, FileMode.Open, FileAccess.Read))
            {
                long shift = 0;
                for (long i = fsB.Length - 1; i >= 0; i--)
                {
                    fsB.Position = i; int bc = fsB.ReadByte();
                    if ((char)bc == DecimalSeparator) continue;
                    int digit = bc - '0';
                    if (digit > 0)
                    {
                        string tDig = fileRes + ".d", tNew = acc + ".n";
                        SwapMultiplyDigit(fileA, tDig, digit, shift);
                        SwapSum(acc, tDig, tNew);
                        File.Delete(acc); File.Delete(tDig); File.Move(tNew, acc);
                    }
                    shift++;
                }
            }
            if (File.Exists(fileRes)) File.Delete(fileRes);
            File.Move(acc, fileRes);
        }

        public static void SwapDivide(string fileA, string fileB, string fileRes)
        {
            string curr = fileRes + ".c", quot = fileRes + ".q";
            File.WriteAllText(curr, "0"); File.WriteAllText(quot, "");
            using (var fsA = new FileStream(fileA, FileMode.Open, FileAccess.Read))
            using (var fsQ = new FileStream(quot, FileMode.Create, FileAccess.Write))
            {
                for (long i = 0; i < fsA.Length; i++)
                {
                    fsA.Position = i; int ca = fsA.ReadByte();
                    if ((char)ca == DecimalSeparator) continue;
                    
                    string tCurr = curr + ".t";
                    string content = File.ReadAllText(curr);
                    File.WriteAllText(tCurr, content == "0" ? ((char)ca).ToString() : content + (char)ca);
                    File.Delete(curr); File.Move(tCurr, curr);

                    int cnt = 0;
                    while (CompareAbs(curr, fileB) >= 0)
                    {
                        string tSub = curr + ".s";
                        SwapSub(curr, fileB, tSub);
                        File.Delete(curr); File.Move(tSub, curr);
                        cnt++;
                    }
                    fsQ.WriteByte((byte)(cnt + '0'));
                }
            }
            if (File.Exists(fileRes)) File.Delete(fileRes);
            File.Move(quot, fileRes); File.Delete(curr);
        }
    }
}
