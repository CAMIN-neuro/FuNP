Error() {
echo -e "\033[38;5;9m\n[ERROR]... $1\033[0m"
}

Warning() {
Col="38;5;184m" # Color code
if [[ ${quiet} != TRUE ]]; then echo  -e "\033[$Col\n[ WARNING ]..... $1 \033[0m"; fi
}
