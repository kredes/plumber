#include <utility>
#include <vector>
#include <iostream>
#include <sstream>

using namespace std;

class PlumberType {
public:
    virtual string repr();
};


class Tube : public PlumberType {
public:
    int length, diameter;
    
    Tube(int length, int diameter) {
        this->length = length;
        this->diameter = diameter;
    }
    
    pair<Tube, Tube> split() {
        return make_pair(Tube(length/2, diameter), Tube(length/2, diameter));
    }
    
    string repr() {  
        stringstream os;
        
        os << "Tube(" << length << ", " << diameter << ")";  
        
        return os.str();  
    }
    
};

class Connector : public PlumberType {
public:
    int diameter;
    
    Connector(int diameter) {
        this->diameter = diameter;
    }
    
    Tube merge(Tube& t1, Tube& t2) {
        return Tube(t1.length + t2.length, diameter);
    }
    
    string repr() {
        stringstream os;
        
        os << "Connector(" << diameter << ")";  
        
        return os.str();  
    }
};

class Tubevector : public PlumberType {
public:
    
    vector<Tube> tubes;
    int max_size;
    
    Tubevector(int max_size) {
        this->max_size = max_size;
        this->tubes = vector<Tube>();
    }
    
    void push(Tube& t) {
        if (tubes.size() == max_size) throw "Tubevector is full";
        tubes.push_back(t);
    }
    
    Tube pop() {
        if (tubes.size() == 0) throw "Tubevector is empty";
        
        Tube t = tubes.back();
        tubes.pop_back();
        
        return t;
    }
    
    bool empty() { return tubes.empty(); }
    
    bool full() { return tubes.size() == max_size; }
    
    string repr() {  
        stringstream os;
        
        os << "Tubevector(" << max_size << ") -> [";  
        
        for (int i = 0; i < tubes.size(); ++i) {
            //os << tubes[i] << ", ";
        }
        
        os << "]";
        
        return os.str();  
    }
};