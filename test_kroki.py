import base64
import zlib
import urllib.request

def generate_erd():
    mermaid_code = """
    erDiagram
        USERS {
            int id PK
            varchar name
        }
    """
    
    # Kroki encoding
    compressed = zlib.compress(mermaid_code.encode('utf-8'), 9)
    b64 = base64.urlsafe_b64encode(compressed).decode('ascii')
    
    url = f"https://kroki.io/mermaid/png/{b64}"
    print("URL:", url)
    
    try:
        urllib.request.urlretrieve(url, "test_erd.png")
        print("Success! Downloaded test_erd.png")
    except Exception as e:
        print("Error:", e)

generate_erd()
