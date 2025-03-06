#!/usr/bin/env python3
import re
import os
import sys

def main(input_file, output_dir, header_output_file):
    # 出力ディレクトリを作成
    os.makedirs(output_dir, exist_ok=True)

    # ヘッダファイル名を取得（パスを除く）
    header_filename = os.path.basename(header_output_file)

    # ファイルを読み込む
    with open(input_file, 'r', encoding='utf-8') as file:
        content = file.read()

    # static inline関数を抽出する
    pattern = re.compile(r'static inline [\s\S]*?\n}\n', re.MULTILINE)
    functions = pattern.findall(content)
    out_functions = [re.sub(r'static inline ', '', function) for function in functions]
    out_functions = [re.sub(r'_dos_bus_err', 'BUS_ERR', function) for function in out_functions]

    # 各関数を個別のファイルに出力
    for i, function in enumerate(out_functions):
        output_file = os.path.join(output_dir, f'zusb{i:02d}.c')
        with open(output_file, 'w', encoding='cp932', newline='\r\n') as file:
            file.write(f'#include "zusb.h"\n\n')
            file.write(function)

    # 関数宣言を作成
    declarations = [re.sub(r'\n{[\s\S]*', ';', function) for function in out_functions]

    # 元のファイルから関数定義を削除し、関数宣言に置き換える
    modified_content = content
    for function, declaration in zip(functions, declarations):
        modified_content = modified_content.replace(function, declaration)

    # 元のファイルのcommon定義をexternに変更する
    modified_content = re.sub(r'(.*) __attribute__ \(\(common\)\)', r'extern \1', modified_content)

    # modified_content内にstdint を含む行があったら削除
    modified_content = re.sub(r'^.*stdint.*\n?', '', modified_content, flags=re.MULTILINE)

    # 関数宣言をヘッダーファイルに出力
    with open(header_output_file, 'w', encoding='cp932', newline='\r\n') as file:
        file.write(modified_content)

    print(f'{len(functions)} functions extracted and saved to {output_dir}')
    print(f'Function declarations saved to {header_output_file}')

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: makefunc.py <input_file> <output_dir> <header_output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = sys.argv[2]
    header_output_file = sys.argv[3]
    main(input_file, output_dir, header_output_file)
