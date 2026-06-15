import urllib.request
import urllib.parse

def generate_erd():
    dot = """
    digraph G {
        USERS [shape=record, label="{USERS|id\nname}"];
    }
    """
    
    url = "https://quickchart.io/graphviz?graph=" + urllib.parse.quote(dot)
    
    try:
        urllib.request.urlretrieve(url, "test_qc.png")
        print("Success! Downloaded test_qc.png")
    except Exception as e:
        print("Error:", e)

generate_erd()
