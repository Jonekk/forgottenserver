#include "timer.h"
#include <iostream>

void Timer::start() {
    m_start = std::chrono::steady_clock::now();
    m_running = true;
}

int Timer::stop() {  // Now returns int
    if (!m_running) return 0;
    
    auto end = std::chrono::steady_clock::now();
    m_running = false;
    
    // Cast duration to milliseconds as integer
    return static_cast<int>(
        std::chrono::duration_cast<std::chrono::milliseconds>(end - m_start).count()
    );
}

void Timer::stopAndPrint(const std::string& message) {
    int elapsed = stop();
    if (!message.empty()) {
        std::cout << message << ": ";
    }
    std::cout << elapsed << " ms\n";
}