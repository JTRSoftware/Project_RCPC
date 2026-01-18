#ifndef SSWAPMATH_H
#define SSWAPMATH_H

#include <string>
#include <cstdint>
#include <functional>

namespace sSwapMath {
    extern char DecimalSeparator;
    extern int BufferSize;

    typedef std::function<void(int64_t, int64_t)> ProgressCallback;
    extern ProgressCallback OnProgress;

    struct NumInfo {
        int64_t IntLen;
        int64_t DecLen;
        bool HasDec;
        int64_t TotalLen;
    };

    NumInfo GetNumInfo(const std::string& filePath);
    void SwapSum(const std::string& fileA, const std::string& fileB, const std::string& fileRes);
    void SwapSub(const std::string& fileA, const std::string& fileB, const std::string& fileRes);
    void SwapMultiply(const std::string& fileA, const std::string& fileB, const std::string& fileRes);
    void SwapDivide(const std::string& fileA, const std::string& fileB, const std::string& fileRes);
    int SwapCompare(const std::string& fileA, const std::string& fileB);
}

#endif
