#ifndef RANDOM_H
#define RANDOM_H

class Random
{
public:
    Random(long seed = -1);
    double ran2();
private:
    long m_idum = 0;
    long *idum = 0;
};

#endif // RANDOM_H
