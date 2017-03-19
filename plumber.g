#header
<<
#include <map>
#include <vector>
#include "types.cc"
#include <string>
#include <iostream>
using namespace std;

// struct to store information about tokens
typedef struct {
  string kind;
  string text;
} Attrib;

// Represents the result of evaluating something
typedef struct {
    bool success;
    
    string type;
    
    Tube *t1, *t2 = NULL;
    Tubevector *vector = NULL;
    Connector connector;
    bool condition;
    int number;
} Evaluation;

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

// Symbols Table
map<string, PlumberType> m;

void printSymbolTable() {
    cout << endl << endl << "Symbols table" << endl;
    cout << "id    | value" << endl;
    cout << "---------------" << endl;
    for(map<string, PlumberType>::iterator it = m.begin(); it != m.end(); ++it) {
        PlumberType elem = it->second;
        cout << it->first << "     | " << elem.repr() << endl;
    }
    cout << endl << endl;
}

// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {    
    if (type == ID) {
        attr->kind = "id";
        attr->text = text;
    }
    else if (type == NUM) {
        attr->kind = "integer";
        attr->text = text;
    } else {
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

/* Forward declarations */
int evaluateNumber(AST *a);
bool evaluateBool(AST *a);
Tube evaluateTube(AST *a);
Tubevector evaluateVector(AST *a);
Connector evaluateConnector(AST *a);
pair<Tube, Tube> evaluateSplit(AST *a);


/*
    Evaluates any instruction that yields a single Tube as a result.
    I.e.: TUBE and MERGE
*/
Tube evaluateTube(AST *a) {
    if (a->kind == "TUBE") {
        int length = evaluateNumber(child(a,0));
        int diameter = evaluateNumber(child(a,1));
        
        return Tube(length, diameter);
        
    } else if (a->kind == "MERGE") {
        Connector c = evaluateConnector(child(a,1));
        Tube t1 = evaluateTube(child(a,0));
        Tube t2 = evaluateTube(child(a,2));
        
        return c.merge(t1, t2);     // TODO: Remove them from memory!!!
    }
    else if (a->kind == "id")
        return (Tube) m[a->text];
    else {
        throw "This shouldn't happen";
    }
}

pair<Tube, Tube> evaluateSplit(AST *a) {
    if (a->kind == "SPLIT") {
        Tube t = evaluateTube(child(a,0));
        return t.split();
    } else {
        throw "This shouldn't happen";
    }
}

// Evaluates the TUBEVECTOR instruction
Tubevector evaluateVector(AST *a) {
    if (a->kind == "TUBEVECTOR") {
        int size = evaluateNumber(child(a,0));
        return Tubevector(size);
    } else if (a->kind == "id") {
        return (Tubevector) m[a->text];
    } else {
        throw "This shouldn't happen";
    }
}

Connector evaluateConnector(AST *a) {
    if (a->kind == "CONNECTOR") {
        int diameter = evaluateNumber(child(a,0));
        return Connector(diameter);
    } else if (a->kind == "id") {
        return (Connector) m[a->text];
    } else {
        throw "This shouldn't happen";
    }
}

int evaluateNumber(AST *a) {
    if (a == NULL) return 0;
    else if (a->kind == "integer")
        return atoi(a->text.c_str());
    else if (a->kind == "LENGTH") {
        Tube t = evaluateTube(child(a,0));
        return t.length;
    }
    else if (a->kind == "DIAMETER") {
        Tube t = evaluateTube(child(a,0));
        return t.diameter;
    } else {
        throw "This shouldn't happen";
    }
}

bool evaluateBool(AST *a) {
    if (a->kind == "AND")
        return evaluateBool(child(a,0)) and evaluateBool(child(a,1));
    else if (a->kind == "OR")
        return evaluateBool(child(a,0)) or evaluateBool(child(a,1));
    else if (a->kind == "NOT")
        return not evaluateBool(child(a,0));
    else if (a->kind == ">")
        return evaluateNumber(child(a,0)) > evaluateNumber(child(a,1));
    else if (a->kind == "<")
        return evaluateNumber(child(a,0)) < evaluateNumber(child(a,1));
    else if (a->kind == "==")
        return evaluateNumber(child(a,0)) == evaluateNumber(child(a,1));
    else if (a->kind == "FULL") {
        Tubevector &tv = evaluateVector(child(a,0));
        return tv.full();
    } else if (a->kind == "EMPTY") {
        Tubevector &tv = evaluateVector(child(a,0));
        return tv.empty();
    } else {
        throw "This shouldn't happen";
    }
}


void execute(AST *a) {
    if (a == NULL) return;
    else if (a->kind == "=") {
        bool split = child(a,2) == NULL ? false : true;
        if (split) {
            pair<Tube, Tube> ev = evaluateSplit(child(a,2));
            m[child(a,0)->text] = ev.first;
            m[child(a,1)->text] = ev.second;
        } else {
            AST *aux = child(a,1);
            if (aux->kind == "TUBEVECTOR")
                m[child(a,0)->text] = evaluateVector(aux);
            else if (aux->kind == "CONNECTOR")
                m[child(a,0)->text] = evaluateConnector(aux);
            else if (aux->kind == "TUBE" or aux->kind == "MERGE")
                m[child(a,0)->text] = evaluateTube(aux);
        }
    } else if (a->kind == "WHILE") {
        bool condition = evaluateBool(child(a,0));
        while (condition) {
            execute(child(a,1));
            condition = evaluateBool(child(a,0));
        }
    }
    // A function
    else cout << evaluateNumber(a) << endl;
    
    execute(a->right);
}

/*
Evaluation evaluate(AST *a) {
    Evaluation eval;
    if (a == NULL) return eval;
    else if (a->kind == "id") 
        PlumberType elem = m[a->text];
        
        if (elem.type() == "Tube")
            eval.t1 = (Tube) elem;
        else if (elem.type == "Tubevector")
            eval.vector = (Tubevector) elem;
        else if (elem.type == "Connector")
            eval.connector = (Connector) elem;
        
        
    else if (a->kind == "integer") 
        
        return atoi(a->text.c_str());
    else if (a->kind == "+")
        
        return evaluate(child(a,0)).number + evaluate(child(a,1)).number;
    else if (a->kind == "-")
        return evaluate(child(a,0)).number - evaluate(child(a,1)).number;
    else if (a->kind == "*")
        return evaluate(child(a,0)).number * evaluate(child(a,1)).number;
    else if (a->kind == "/")
        return evaluate(child(a,0)).number / evaluate(child(a,1)).number;
    
    return eval;
}


void execute(AST *a) {
    if (a == NULL) return;
    else if (a->kind == "=") {
        bool split = child(a,2) == NULL ? false : true;
        if (split) {
            Evaluation ev = evaluate(child(a,2));
            m[child(a,0)->text] = ev.t1;
            m[child(a,1)->text] = ev.t2;
        } else {
            AST *aux = child(a,1);
            
            
            if (aux->kind == "TUBEVECTOR")
                m[child(a,0)->text] = evaluate(aux).vector;
            else if (aux->kind == "TUBE")
                m[child(a,0)->text] = evaluate(aux).t1;
        }
    } else if (a->kind == "WHILE") {
        Evaluation ev = evaluate(child(a,0));
        while (ev.condition) {
            execute(child(a,1));
            ev = evaluate(child(a,0));
        }
    } 
    // A function
    else cout << evaluate(a).number << endl;
    
    execute(a->right);
}
*/

int main() {
  AST *root = NULL;
  ANTLR(plumber(&root), stdin);
  ASTPrint(root);
  execute(root);
  
  printSymbolTable();
}
>>

#lexclass START

#token TUBEVECTOR "TUBEVECTOR"
#token OF "OF"
#token PUSH "PUSH"
#token FULL "FULL"
#token EMPTY "EMPTY"
#token POP "POP"

#token TUBE "TUBE"
#token LENGTH "LENGTH"
#token DIAMETER "DIAMETER"
#token SPLIT "SPLIT"

#token CONNECTOR "CONNECTOR"

#token MERGE "MERGE"


#token ENDWHILE "ENDWHILE"
#token WHILE "WHILE"


#token AND "AND"
#token OR "OR"
#token NOT "NOT"

#token GT ">"
#token LT "<"
#token EQ "=="

// Keep the "=" below the "=="!
#token ASSIG "="
#token PLUS "\+"
#token MINUS "\-"
#token TIMES "\*"
#token DIV "/"

#token COMMA ","
#token LPAREN "\("
#token RPAREN "\)"

#token NUM "[0-9]+"
#token ID "[a-zA-Z][0-9a-zA-Z]*"
#token SPACE "[\ \n\t]" << zzskip();>>

plumber: (ops)* <<#0=createASTlist(_sibling);>>;

ops
  : action
  | whileloop
  | function
  ;


/* 
   BOOLEAN
   Boolean expressions with standard precedences. Allows parenthesis.
*/
boolexpr: bterm2 (OR^ bterm2)*;
bterm2: bterm1 (AND^ bterm1);
bterm1
  : NOT^ bterm
  | bterm;
bterm
  : expr (GT^ expr | LT^ expr | EQ^ expr) // Should right atom be expr? Like x > 2 + 3 * 5
  | boolatom; 
boolatom: boolean_function | LPAREN! boolexpr RPAREN!;

 
/*
   LOOPS
*/
oplist: (ops)* <<#0=createASTlist(_sibling);>>;

whileloop
  : WHILE^ LPAREN! boolexpr RPAREN! oplist ENDWHILE!;

/* 
   ARITHMETICAL 
   Arithmetical expresions with standard precedences.
   Parenthesis are NOT allowed in these to avoid ambiguities.
*/
expr: term (PLUS^ term | MINUS^ term)*;
term: atom (MULT^ atom | DIV^ atom)*;
//atom: NUM | ID | numerical_function;
atom: NUM | numerical_function;



/* 
   ACTIONS 
   Whatever thing that does not return any value.
*/
assign
  : ID ASSIG^ (ID | type_function)
  | LPAREN! ID COMMA! ID RPAREN! ASSIG^ split;    // (T1, T2) = SPLIT T3
pop
  : POP^ ID ID;
push
  : PUSH^ ID ID;

action: assign | pop | push;


/* 
   FUNCTIONS
   Whatever thing that returns a value.
*/
tubevector: TUBEVECTOR^ OF! expr;
tube: TUBE^ expr expr;
connector: CONNECTOR^ expr;

split: SPLIT^ ID;
merge
  : MERGE^ (merge | ID) ID (merge | ID);

length: LENGTH^ LPAREN! ID RPAREN!;
diameter: DIAMETER^ LPAREN! ID RPAREN!;

empty: EMPTY^ LPAREN! ID RPAREN!;
full: FULL^ LPAREN! ID RPAREN!;

// SPLIT is NOT included in type_function for convenience
type_function: tubevector | tube | connector | merge;
numerical_function: length | diameter;
boolean_function: empty | full;

function: type_function | numerical_function | boolean_function | split;
