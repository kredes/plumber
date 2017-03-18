#header
<<
#include <map>
#include <string>
#include <iostream>
using namespace std;

// struct to store information about tokens
typedef struct {
  string kind;
  string text;
} Attrib;

// function to fill token information (predeclaration)
void zzcr_attr(Attrib *attr, int type, char *text);

// fields for AST nodes
#define AST_FIELDS string kind; string text;
#include "ast.h"

// macro to create a new AST node (and function predeclaration)
#define zzcr_ast(as,attr,ttype,textt) as=createASTnode(attr,ttype,textt)
AST* createASTnode(Attrib* attr, int ttype, char *textt);
>>

<<
#include <cstdlib>
#include <cmath>

map<string, int> m;

void printSymbolTable() {
    cout << endl << endl << "Symbols table" << endl;
    cout << "name  | value" << endl;
    cout << "---------------" << endl;
    for(map<string, int>::const_iterator it = m.begin(); it != m.end(); ++it) {
        cout << it->first << "     | " << it->second << endl;
    }
    cout << endl << endl;
}

// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {
  
  cerr << "zzcr_attr -> text: " << text << endl;
  
  if (type == NUM) {
    attr->kind = "intconst";
    attr->text = text;
  }
  else if (type == ID) {
    cerr << "This is an id: " << text << endl;
    attr->kind = "id";
    attr->text = text;
    m[text] = 0;
  }
  else {
    cerr << "This is: " << text << endl;
    attr->kind = text;
    attr->text = "";
  }
}

// function to create a new AST node
AST* createASTnode(Attrib* attr, int type, char* text) {
  AST* as = new AST;
  as->kind = attr->kind; 
  as->text = attr->text;
  as->right = NULL; 
  as->down = NULL;
  return as;
}

/// get nth child of a tree. Count starts at 0.
/// if no such child, returns NULL
AST* child(AST *a,int n) {
 AST *c=a->down;
 for (int i=0; c!=NULL && i<n; i++) c=c->right;
 return c;
} 

/// print AST, recursively, with indentation
void ASTPrintIndent(AST *a,string s)
{
  if (a==NULL) return;

  cout<<a->kind;
  if (a->text!="") cout<<"("<<a->text<<")";
  cout<<endl;

  AST *i = a->down;
  while (i!=NULL && i->right!=NULL) {
    cout<<s+"  \\__";
    ASTPrintIndent(i,s+"  |"+string(i->kind.size()+i->text.size(),' '));
    i=i->right;
  }
  
  if (i!=NULL) {
      cout<<s+"  \\__";
      ASTPrintIndent(i,s+"   "+string(i->kind.size()+i->text.size(),' '));
      i=i->right;
  }
}

/// print AST 
void ASTPrint(AST *a)
{
  while (a!=NULL) {
    cout<<" ";
    ASTPrintIndent(a,"");
    a=a->right;
  }
}

int evaluate(AST *a) {
    if (a == NULL) return 0;
    else if (a->kind == "id") return m[a->text];
    else if (a->kind == "intconst")
        return atoi(a->text.c_str());
    else if (a->kind == "+")
        return evaluate(child(a,0)) + evaluate(child(a,1));
    else if (a->kind == "-")
        return evaluate(child(a,0)) - evaluate(child(a,1));
    else if (a->kind == "*")
        return evaluate(child(a,0)) * evaluate(child(a,1));
    else if (a->kind == "/")
        return evaluate(child(a,0)) / evaluate(child(a,1));
}

void execute(AST *a) {
    if (a == NULL) return;
    else if (a->kind == ":=") {
        m[child(a, 0)->text] = evaluate(child(a,1));
    }
    //a->kind == "write"
    else {
        cout << evaluate(child(a,0)) << endl;
    }
    
    execute(a->right);
}
    
    
int main() {
    AST *root = NULL;
    ANTLR(program(&root), stdin);
    ASTPrint(root);
    //cout << evaluate(root) << endl;
    execute(root);
    
    printSymbolTable();
}
>>

#lexclass START
#token WRITE "write"
#token ASSIG ":="
#token NUM "[0-9]+"
#token PLUS "\+"
#token MINUS "\-"
#token MULT "\*"
#token DIV "/"
#token LPAREN "\("
#token RPAREN "\)"
#token SPACE "[\ \n]" << zzskip();>>
#token ID "[a-zA-Z]"

program: (instruction)*;
instruction: ID ASSIG^ expr | WRITE^ expr;
expr : term (PLUS^ term | MINUS^ term)*;
term : atom (MULT^ atom | DIV^ atom)*;
atom : ID | NUM | LPAREN! expr RPAREN!;

