#ifndef SMATH_H
#define SMATH_H

#include <string>
#include <algorithm>

namespace sMath {
    extern char DecimalSeparator;

    std::string CleanNumber(std::string sV);
    std::string Sum(std::string sA, std::string sB);
    std::string Sub(std::string sA, std::string sB);
    std::string Multiply(std::string sA, std::string sB);
    std::string Divide(std::string sA, std::string sB);
}

#endif
