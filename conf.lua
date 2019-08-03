function love.conf(t)
   t.window.width, t.window.height = 800, 600
   t.releases = {
      title = 'backpackless',
      package = 'backpackless',
      author = 'Andrew Kravchuk',
      email = 'awkravchuk@gmail.com',
      description = "A dungeon crawler with some sudden twist regarding hero's backpack",
      homepage = 'https://awkravchuk.itch.io/backpackless',
      excludeFileList = {"README.md", "Makefile", "license.txt", ".fnl"},
      compile = true,
   }
end
