#ifndef TIMER_HPP
#define TIMER_HPP

#include <chrono>
#include <string>

class Timer {
public:
    void start();
    int stop();  // Changed to return int
    void stopAndPrint(const std::string& message = "");
    
private:
    std::chrono::time_point<std::chrono::steady_clock> m_start;
    bool m_running = false;
};

#endif // TIMER_HPP