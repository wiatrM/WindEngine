#include <iostream>
#include <memory>

#include <SFML/Graphics.hpp>

int main()
{
  const unsigned width{ 1280 };
  const unsigned height{ 720 };
  const std::string title{ "CMake Example" };
  auto &&window = sf::RenderWindow({ width, height }, title);


  while (window.isOpen()) {
    sf::Event event{};
    while (window.pollEvent(event)) {
      if (event.type == sf::Event::Closed) { window.close(); }
    }

    window.clear();
    window.display();
  }
}