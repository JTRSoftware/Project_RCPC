import os

class SMath:
    decimal_separator = '.'

    @staticmethod
    def is_negative(s_v):
        return s_v.startswith('-')

    @staticmethod
    def get_abs(s_v):
        return s_v[1:] if s_v.startswith('-') else s_v

    @staticmethod
    def clean_number(s_v):
        neg = SMath.is_negative(s_v)
        val = SMath.get_abs(s_v)
        if not val: return "0"

        # Zeros esquerda
        while len(val) > 1 and val[0] == '0' and val[1] != SMath.decimal_separator:
            val = val[1:]

        if SMath.decimal_separator in val:
            dot_pos = val.find(SMath.decimal_separator)
            while len(val) > dot_pos + 1 and val[-1] == '0':
                val = val[:-1]
            if val[-1] == SMath.decimal_separator:
                val = val[:-1]

        if not val or val == SMath.decimal_separator: val = "0"
        return ("-" + val) if (neg and val != "0") else val

    @staticmethod
    def align_strings(s_a, s_b):
        dot_a = s_a.find(SMath.decimal_separator)
        dot_b = s_b.find(SMath.decimal_separator)

        dec_a = 0 if dot_a < 0 else len(s_a) - dot_a - 1
        dec_b = 0 if dot_b < 0 else len(s_b) - dot_b - 1

        while dec_a < dec_b:
            if dot_a < 0: 
                s_a += SMath.decimal_separator
                dot_a = len(s_a) - 1
            s_a += "0"
            dec_a += 1
        while dec_b < dec_a:
            if dot_b < 0: 
                s_b += SMath.decimal_separator
                dot_b = len(s_b) - 1
            s_b += "0"
            dec_b += 1

        int_a = len(s_a) if dot_a < 0 else dot_a
        int_b = len(s_b) if dot_b < 0 else dot_b

        while int_a < int_b: s_a = "0" + s_a; int_a += 1
        while int_b < int_a: s_b = "0" + s_b; int_b += 1

        return s_a, s_b

    @staticmethod
    def sum(s_a, s_b):
        if SMath.is_negative(s_a) and SMath.is_negative(s_b):
            return "-" + SMath._internal_sum(SMath.get_abs(s_a), SMath.get_abs(s_b))
        if SMath.is_negative(s_a): return SMath._internal_sub(SMath.get_abs(s_b), SMath.get_abs(s_a))
        if SMath.is_negative(s_b): return SMath._internal_sub(SMath.get_abs(s_a), SMath.get_abs(s_b))
        return SMath.clean_number(SMath._internal_sum(s_a, s_b))

    @staticmethod
    def _internal_sum(s_a, s_b):
        s_a, s_b = SMath.align_strings(s_a, s_b)
        res = []
        carry = 0
        for i in range(len(s_a) - 1, -1, -1):
            if s_a[i] == SMath.decimal_separator:
                res.append(SMath.decimal_separator)
                continue
            d_sum = int(s_a[i]) + int(s_b[i]) + carry
            carry = d_sum // 10
            res.append(str(d_sum % 10))
        if carry > 0: res.append(str(carry))
        return "".join(res[::-1])

    @staticmethod
    def sub(s_a, s_b):
        if SMath.is_negative(s_b): return SMath.sum(s_a, SMath.get_abs(s_b))
        if SMath.is_negative(s_a): return "-" + SMath._internal_sum(SMath.get_abs(s_a), s_b)
        return SMath.clean_number(SMath._internal_sub(s_a, s_b))

    @staticmethod
    def _internal_sub(s_a, s_b):
        s_a, s_b = SMath.align_strings(s_a, s_b)
        neg = False
        if s_a < s_b:
            s_a, s_b = s_b, s_a
            neg = True
        
        res = []
        borrow = 0
        for i in range(len(s_a) - 1, -1, -1):
            if s_a[i] == SMath.decimal_separator:
                res.append(SMath.decimal_separator)
                continue
            diff = int(s_a[i]) - int(s_b[i]) - borrow
            if diff < 0:
                diff += 10
                borrow = 1
            else:
                borrow = 0
            res.append(str(diff))
        
        s_res = "".join(res[::-1])
        return ("-" + s_res) if neg else s_res

    @staticmethod
    def multiply(s_a, s_b):
        res_neg = SMath.is_negative(s_a) ^ SMath.is_negative(s_b)
        s_a, s_b = SMath.get_abs(s_a), SMath.get_abs(s_b)

        dot_a = s_a.find(SMath.decimal_separator)
        dec_a = 0 if dot_a < 0 else len(s_a) - dot_a - 1
        int_a = s_a.replace(SMath.decimal_separator, "")

        dot_b = s_b.find(SMath.decimal_separator)
        dec_b = 0 if dot_b < 0 else len(s_b) - dot_b - 1
        int_b = s_b.replace(SMath.decimal_separator, "")

        total_decs = dec_a + dec_b
        final_res = "0"

        for i in range(len(int_b) - 1, -1, -1):
            digit_b = int(int_b[i])
            if digit_b == 0: continue
            current_res = []
            carry = 0
            for j in range(len(int_a) - 1, -1, -1):
                digit_a = int(int_a[j])
                prod = (digit_a * digit_b) + carry
                carry = prod // 10
                current_res.append(str(prod % 10))
            if carry > 0: current_res.append(str(carry))
            s_current = "".join(current_res[::-1]) + ("0" * (len(int_b) - 1 - i))
            final_res = SMath._internal_sum(final_res, s_current)

        if total_decs > 0:
            while len(final_res) <= total_decs: final_res = "0" + final_res
            final_res = final_res[:len(final_res)-total_decs] + SMath.decimal_separator + final_res[len(final_res)-total_decs:]

        result = ("-" + final_res) if res_neg else final_res
        return SMath.clean_number(result)

    @staticmethod
    def divide(s_a, s_b):
        if SMath.clean_number(s_b) == "0": return "0"
        res_neg = SMath.is_negative(s_a) ^ SMath.is_negative(s_b)
        s_a, s_b = SMath.get_abs(s_a), SMath.get_abs(s_b)

        t_a, t_b = SMath.align_strings(s_a, s_b)
        t_a = t_a.replace(SMath.decimal_separator, "")
        t_b = t_b.replace(SMath.decimal_separator, "")
        t_a, t_b = SMath.clean_number(t_a), SMath.clean_number(t_b)

        quotient = ""
        current = ""
        precision = 0
        has_decimal = False

        for i in range(len(t_a) + 10):
            if i < len(t_a): current += t_a[i]
            else:
                if not has_decimal:
                    if not quotient: quotient = "0"
                    quotient += SMath.decimal_separator
                    has_decimal = True
                current += "0"
                precision += 1
            
            current = SMath.clean_number(current)
            count = 0
            while SMath._compare_abs(current, t_b) >= 0:
                current = SMath._internal_sub(current, t_b)
                count += 1
            
            if quotient or count > 0 or i == len(t_a) - 1:
                quotient += str(count)
            
            if i >= len(t_a) - 1 and SMath.clean_number(current) == "0": break
            if precision >= 10: break

        final_quot = ("-" + quotient) if (res_neg and quotient != "0") else quotient
        return SMath.clean_number(final_quot)

    @staticmethod
    def _compare_abs(s_a, s_b):
        s_a, s_b = SMath.clean_number(s_a), SMath.clean_number(s_b)
        s_a, s_b = SMath.align_strings(s_a, s_b)
        if s_a == s_b: return 0
        return 1 if s_a > s_b else -1
