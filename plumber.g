#header
<<
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
// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {
    attr->kind = text;
    attr->text = "";
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

/// create a new "list" AST node with one element
AST* createASTlist(AST *child) {
 AST *as=new AST;
 as->kind="list";
 as->right=NULL;
 as->down=child;
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

int main() {
  AST *root = NULL;
  ANTLR(plumber(&root), stdin);
  ASTPrint(root);
}
>>

#lexclass START
#token TUBEVECTOR "TUBEVECTOR"
#token TUBE "TUBE"
#token CONNECTOR "CONNECTOR"
#token DIAMETER "DIAMETER"
#token SPLIT "SPLIT"
#token MERGE "MERGE"
#token PUSH "PUSH"
#token ENDWHILE "ENDWHILE"
#token WHILE "WHILE"
#token FULL "FULL"
#token EMPTY "EMPTY"
#token LENGTH "LENGTH"
#token POP "POP"
#token AND "AND"
#token OR "OR"
#token NOT "NOT"
#token PLUS "\+"
#token MINUS "\-"
#token TIMES "\*"
#token DIV "/"
#token GT ">"
#token LT "<"
#token EQ "=="
#token LPAREN "\("
#token RPAREN "\)"
#token ID "[a-zA-Z][0-9a-zA-Z]*"
#token NUM "[0-9]+
#token SPACE "[\ \n]" << zzskip();>>

plumber: (ops)* <<#0=createASTlist(_sibling);>>;
boolexpr: (NOT^)* expr (AND^ boolexpr | OR^ boolexpr | expr | atom)*
expr:
term: atom (MULT^ atom | DIV^ atom)
merge: MERGE^ ID ID ID
pop: POP^ ID ID
push: PUSH^ ID ID
action: merge | pop | push

tube TUBE atom atom
connector: CONNECTOR atom atom
length: LENGTH^ LPAREN! ID RPAREN!
empty: EMPTY^ LPAREN! ID RPAREN!
full: FULL^ LPAREN! ID RPAREN!
function: tube | connector | split | length | empty | full
atom: NUM | ID |
//...
