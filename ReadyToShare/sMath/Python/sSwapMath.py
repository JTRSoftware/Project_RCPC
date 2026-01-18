import os

class SSwapMath:
    decimal_separator = '.'
    buffer_size = 1024 * 512
    on_progress = None # Callback function(current, total)

    @staticmethod
    def get_num_info(file_path):
        info = {'int_len': 0, 'dec_len': 0, 'has_dec': False, 'total_len': 0}
        if not os.path.exists(file_path): return info
        
        total_len = os.path.getsize(file_path)
        info['total_len'] = total_len
        dec_pos = -1
        
        with open(file_path, 'rb') as f:
            while True:
                chunk = f.read(65536)
                if not chunk: break
                for i, byte in enumerate(chunk):
                    if chr(byte) == SSwapMath.decimal_separator:
                        dec_pos = f.tell() - len(chunk) + i
                        break
                if dec_pos != -1: break
        
        if dec_pos != -1:
            info['has_dec'] = True
            info['int_len'] = dec_pos
            info['dec_len'] = total_len - dec_pos - 1
        else:
            info['int_len'] = total_len
            info['dec_len'] = 0
        return info

    @staticmethod
    def reverse_file(source, target):
        total_size = os.path.getsize(source)
        with open(source, 'rb') as f_in, open(target, 'wb') as f_out:
            total_blocks = total_size // SSwapMath.buffer_size
            remainder = total_size % SSwapMath.buffer_size
            
            if remainder > 0:
                f_in.seek(total_size - remainder)
                chunk = f_in.read(remainder)
                f_out.write(chunk[::-1])
                
            for i in range(total_blocks - 1, -1, -1):
                f_in.seek(i * SSwapMath.buffer_size)
                chunk = f_in.read(SSwapMath.buffer_size)
                f_out.write(chunk[::-1])

    @staticmethod
    def create_normalized_file(source, target, target_int, target_dec):
        info = SSwapMath.get_num_info(source)
        with open(source, 'rb') as f_in, open(target, 'wb') as f_out:
            for _ in range(target_int - info['int_len']): f_out.write(b'0')
            remaining = info['int_len']
            while remaining > 0:
                chunk = f_in.read(min(SSwapMath.buffer_size, remaining))
                f_out.write(chunk)
                remaining -= len(chunk)
            f_out.write(SSwapMath.decimal_separator.encode())
            if info['has_dec']:
                f_in.seek(info['int_len'] + 1)
                remaining = info['dec_len']
                while remaining > 0:
                    chunk = f_in.read(min(SSwapMath.buffer_size, remaining))
                    f_out.write(chunk)
                    remaining -= len(chunk)
            for _ in range(target_dec - info['dec_len']): f_out.write(b'0')

    @staticmethod
    def swap_compare(file_a, file_b):
        info_a = SSwapMath.get_num_info(file_a)
        info_b = SSwapMath.get_num_info(file_b)
        if info_a['int_len'] > info_b['int_len']: return 1
        if info_a['int_len'] < info_b['int_len']: return -1
        
        with open(file_a, 'rb') as f_a, open(file_b, 'rb') as f_b:
            for _ in range(info_a['int_len']):
                ca, cb = f_a.read(1), f_b.read(1)
                if ca > cb: return 1
                if ca < cb: return -1
            
            for i in range(1, max(info_a['dec_len'], info_b['dec_len']) + 1):
                ca, cb = b'0', b'0'
                if i <= info_a['dec_len']:
                    f_a.seek(info_a['int_len'] + i)
                    ca = f_a.read(1)
                if i <= info_b['dec_len']:
                    f_b.seek(info_b['int_len'] + i)
                    cb = f_b.read(1)
                if ca > cb: return 1
                if ca < cb: return -1
        return 0

    @staticmethod
    def swap_sum(file_a, file_b, file_res):
        info_a = SSwapMath.get_num_info(file_a)
        info_b = SSwapMath.get_num_info(file_b)
        max_int, max_dec = max(info_a['int_len'], info_b['int_len']), max(info_a['dec_len'], info_b['dec_len'])
        norm_a, norm_b, tmp_res = file_a + ".norm", file_b + ".norm", file_res + ".tmp"
        SSwapMath.create_normalized_file(file_a, norm_a, max_int, max_dec)
        SSwapMath.create_normalized_file(file_b, norm_b, max_int, max_dec)
        
        with open(norm_a, 'rb') as f_a, open(norm_b, 'rb') as f_b, open(tmp_res, 'wb') as f_res:
            carry, total = 0, os.path.getsize(norm_a)
            for i in range(total - 1, -1, -1):
                f_a.seek(i); f_b.seek(i)
                ba, bb = f_a.read(1)[0], f_b.read(1)[0]
                if chr(ba) == SSwapMath.decimal_separator:
                    f_res.write(SSwapMath.decimal_separator.encode())
                    continue
                d_sum = (ba - 48) + (bb - 48) + carry
                carry = d_sum // 10
                f_res.write(str(d_sum % 10).encode())
            if carry > 0: f_res.write(str(carry).encode())
        
        SSwapMath.reverse_file(tmp_res, file_res)
        os.remove(norm_a); os.remove(norm_b); os.remove(tmp_res)

    @staticmethod
    def swap_sub(file_a, file_b, file_res):
        info_a, info_b = SSwapMath.get_num_info(file_a), SSwapMath.get_num_info(file_b)
        max_int, max_dec = max(info_a['int_len'], info_b['int_len']), max(info_a['dec_len'], info_b['dec_len'])
        norm_a, norm_b, tmp_res = file_a + ".norm", file_b + ".norm", file_res + ".tmp"
        SSwapMath.create_normalized_file(file_a, norm_a, max_int, max_dec)
        SSwapMath.create_normalized_file(file_b, norm_b, max_int, max_dec)
        
        with open(norm_a, 'rb') as f_a, open(norm_b, 'rb') as f_b, open(tmp_res, 'wb') as f_res:
            borrow, total = 0, os.path.getsize(norm_a)
            for i in range(total - 1, -1, -1):
                f_a.seek(i); f_b.seek(i)
                ba, bb = f_a.read(1)[0], f_b.read(1)[0]
                if chr(ba) == SSwapMath.decimal_separator:
                    f_res.write(SSwapMath.decimal_separator.encode())
                    continue
                diff = (ba - 48) - (bb - 48) - borrow
                if diff < 0: diff += 10; borrow = 1
                else: borrow = 0
                f_res.write(str(diff).encode())
        
        SSwapMath.reverse_file(tmp_res, file_res)
        os.remove(norm_a); os.remove(norm_b); os.remove(tmp_res)

    @staticmethod
    def swap_multiply_digit(file_in, file_res, digit, shift):
        temp_tmp = file_res + ".tmp"
        with open(file_in, 'rb') as f_in, open(temp_tmp, 'wb') as f_res:
            carry = 0
            for _ in range(shift): f_res.write(b'0')
            size = os.path.getsize(file_in)
            for i in range(size - 1, -1, -1):
                f_in.seek(i)
                ba = f_in.read(1)[0]
                if chr(ba) == SSwapMath.decimal_separator: continue
                prod = (ba - 48) * digit + carry
                carry = prod // 10
                f_res.write(str(prod % 10).encode())
            if carry > 0: f_res.write(str(carry).encode())
        SSwapMath.reverse_file(temp_tmp, file_res)
        os.remove(temp_tmp)

    @staticmethod
    def swap_multiply(file_a, file_b, file_res):
        temp_acc = file_res + ".acc"
        with open(temp_acc, 'w') as f: f.write("0")
        size_b = os.path.getsize(file_b)
        shift = 0
        with open(file_b, 'rb') as f_b:
            for i in range(size_b - 1, -1, -1):
                f_b.seek(i)
                bc = f_b.read(1)[0]
                if chr(bc) == SSwapMath.decimal_separator: continue
                digit = bc - 48
                if digit > 0:
                    temp_digit = file_res + ".digit"
                    SSwapMath.swap_multiply_digit(file_a, temp_digit, digit, shift)
                    temp_new = temp_acc + ".new"
                    SSwapMath.swap_sum(temp_acc, temp_digit, temp_new)
                    os.remove(temp_acc); os.remove(temp_digit); os.rename(temp_new, temp_acc)
                shift += 1
        if os.path.exists(file_res): os.remove(file_res)
        os.rename(temp_acc, file_res)

    @staticmethod
    def swap_divide(file_a, file_b, file_res):
        curr, quot = file_res + ".curr", file_res + ".quot"
        with open(curr, 'w') as f: f.write("0")
        with open(quot, 'w') as f: f.write("")
        size_a = os.path.getsize(file_a)
        with open(file_a, 'rb') as f_a:
            for i in range(size_a):
                f_a.seek(i)
                ba = f_a.read(1)[0]
                if chr(ba) == SSwapMath.decimal_separator: continue
                temp_curr = curr + ".tmp"
                with open(curr, 'r') as f_c:
                    content = f_c.read()
                    with open(temp_curr, 'w') as f_t:
                        f_t.write(ba if content == "0" else content + chr(ba)) # Simplified append
                os.remove(curr); os.rename(temp_curr, curr)
                count = 0
                while SSwapMath.swap_compare(curr, file_b) >= 0:
                    temp_sub = curr + ".sub"
                    SSwapMath.swap_sub(curr, file_b, temp_sub)
                    os.remove(curr); os.rename(temp_sub, curr)
                    count += 1
                with open(quot, 'a') as f_q: f_q.write(str(count))
        if os.path.exists(file_res): os.remove(file_res)
        os.rename(quot, file_res)
        os.remove(curr)
