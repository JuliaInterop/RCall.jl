"""
A utility function to help install packages. This is needed because
R"install.packages(pkgs)" doesn't work.
"""
function install_packages(pkgs)
    run(`R -e "install.packages($pkg)"`)
end
