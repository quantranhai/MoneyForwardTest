import requests
import sys
from requests import status_codes

def Correct_ID(i,j):
    content = requests.get('https://sample-accounts-api.herokuapp.com/{}/{}'.format(i,j))
    code = requests.head('https://sample-accounts-api.herokuapp.com/{}/{}'.format(i,j))
    return (content.text,code.status_code)

try:
    resource = sys.argv[1]
    id = int(sys.argv[2])
    if resource != "users" and resource != "accounts":
        print('first argument must be users or accounts')
    result = Correct_ID(resource,id)[0]
    response_code = Correct_ID(resource,id)[1]
    #print(response_code)
    #print(result)
    if response_code == 200:
        print(result)
    elif response_code == 404:
        print(f'{resource} {id} not found')
    else:
        exit(1)
except:
    print('error')
    
