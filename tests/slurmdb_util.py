
def convert_tres_str(tres):
    TRES = {'1':'cpu', '2':'mem', '3': 'energy', '4':'node', '5':'gres/gpu'}
    
    if tres == "":
        return ""
    ip_tres_list = tres.split(',')
    op_tres_list = []
    for element in ip_tres_list:
        [key, value] = element.split('=')
        if key == '2' :
            mega_byte = 'M'
            op_tres_list.append(TRES[key] + "=" + value + mega_byte)
        else :
            op_tres_list.append(TRES[key] + "=" + value)
    return ','.join(op_tres_list)

def tres_to_resource(tres, type_resource):
    TRES = {'1':'cpu', '2':'mem', '3': 'energy', '4':'node', '5':'gres/gpu'}
    
    if tres == "":
        return ""
    tres_list = tres.split(',')
    print("---- Tres:", tres_list, "--Type-res:",type_resource)
    for element in tres_list:
        [key, value] = element.split('=')
        print("key", key, "value", value)
        if key.decode('utf-8') == '1' and type_resource == 'cpu':
            return str(value)
        elif key.decode('utf-8') == '2' and type_resource == 'mem':
            return str(value)
        elif key == u'3' and type_resource == 'energy':
            return str(value)
        elif key.decode('utf-8') == '4' and type_resource == 'node':
            return str(value)
        elif key == u'5' and type_resource == 'gres/gpu':
            return str(value)
    for dict_key, dict_val in TRES.iteritems():
        if dict_val == type_resource:
            return ''
    return None
