#ifndef RANDOM_H
#define RANDOM_H

class Random
{
public:
    Random(long seed = -1);
    double ran2();
private:
    long m_idum;
    long *idum;
};

#endif // RANDOM_H
