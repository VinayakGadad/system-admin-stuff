#!/usr/bin/env bash

printf "Enter First name of New Hire :"
read fname
if [[ -z "$fname" ]]; then
    echo "Firstname not entered, retry again"
    exit 1
fi

printf "\nEnter Last name of New Hire :"
read lname
if [[ -z "$lname" ]]; then
    echo "Lastname not entered, retry again"
    exit 1
fi

printf "\nEnter Email address of New Hire :"
read email
if [[ -z "$email" ]]; then
    echo "Email address not entered, retry again"
    exit 1
fi

printf "\nEnter Password for $fname $lname: "
read USERPASS
if [[ -z "$USERPASS" ]]; then
    echo "Password not entered, retry again"
    exit 1
fi

LDAPpassword=ldapPassw0rd

printf "\nEnter Team number you want to add $fname $lname :"
printf "\nTeamName1     --> 101 "
printf "\nTeamName2     --> 102 "
printf "\nTeamName3     --> 103 "
printf "\nTeamName4     --> 204 "
printf "\nTeamName5     --> 214 "
read gidnumber
if [[ -z "$gidnumber" ]]; then
    echo "Team name not selected, retry again"
    exit 1
fi

if [[ "$gidnumber" =~ ^(101|102|103|204|214)$ ]]; then
    case ${gidnumber} in
        101) group="TeamName1" ;;
        102) group="TeamName2" ;;
        103) group="TeamName3" ;;
        204) group="TeamName4" ;;
        214) group="TeamName5" ;;
    esac
else
    echo "Enter valid Team Name"
    exit 1
fi

function getMaxUid ()
{
   n=0
   for i in $(ldapsearch -x -w '$LDAPpassword' -D "cn=io-role-user,cn=cnName,cn=Team,dc=companyname,dc=com" "(uidNumber=*)" uidNumber -S uidNumber | grep uidNumber | tail -n1);
   do \
       ldaparry[$n]=$i
       let n+=1
   done

    if [ "${ldaparry[0]}" == "uidNumber:" ]; then
        echo $((${ldaparry[1]}+1))
        return 0
    else
        return -1
    fi
}

function password() {
    slappasswd -h {SHA} -s $USERPASS
    return 1
}

    printf "#Entry 1: cn=$fname $lname,cn=$group,dc=companyname,dc=com" > ~/Documents/NewUser.ldif
    if [ "$gidnumber" = "101" ] || [ "$gidnumber" = "102" ] || [ "$gidnumber" = "103" ]; then
        printf "\ndn: cn=$fname $lname,cn=$group,cn=TeamName1,dc=companyname,dc=com" >> ~/Documents/NewUser.ldif
    elif [ "$gidnumber" = "202" ] || [ "$gidnumber" = "214" ]; then
        printf "dn: cn=$fname $lname,cn=$group,cn=TeamName2,dc=companyname,dc=com" >> ~/Documents/NewUser.ldif
    else
        printf "\ndn: cn=$fname $lname,cn=$group,dc=companyname,dc=com" >> ~/Documents/NewUser.ldif
    fi
    printf "\ncn: $fname $lname" >> ~/Documents/NewUser.ldif
    printf "\ngidnumber: $gidnumber" >> ~/Documents/NewUser.ldif
    printf "\ngivenname: $fname" >> ~/Documents/NewUser.ldif
    printf "\nhomedirectory: /home/$email" >> ~/Documents/NewUser.ldif
    printf "\nloginshell: /bin/sh" >> ~/Documents/NewUser.ldif
    printf "\nmail: $email" >> ~/Documents/NewUser.ldif
    printf "\nobjectclass: inetOrgPerson" >> ~/Documents/NewUser.ldif
    printf "\nobjectclass: posixAccount" >> ~/Documents/NewUser.ldif
    printf "\nobjectclass: top" >> ~/Documents/NewUser.ldif
    printf "\nsn: $lname" >> ~/Documents/NewUser.ldif
    printf "\nuid: $email" >> ~/Documents/NewUser.ldif
    printf "\nuidNumber: `getMaxUid`" >> ~/Documents/NewUser.ldif
    printf "\nuserpassword: `password`" >> ~/Documents/NewUser.ldif

cat ~/Documents/NewUser.ldif
printf "Hello, $fname \n\nYour LDAP credentials are:\n Email/Username = $email\n Password = $USERPASS\n\n" > ~/Documents/Emailfile.txt
cat ~/Documents/Emailfile.txt | mail -s "Your LDAP account is created" $email -r LDAPCreds


printf "\n**** LDAP user $fname $lname created. ****\n\n"

while true; do
    read -p "Do you wish to add above user in LDAP? [Y/N] ?" yn
    case $yn in
        [Yy]* ) ldapadd -x -w '$LDAPpassword' -D "cn=io-role-user,cn=cnName,cn=Team,dc=companyname,dc=com" -f ~/Documents/NewUser.ldif; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac

    if [ ! -f ~/Documents/Emailfile.txt ]; then
        printf "Hello, $fname \nYour LDAP credentials are:\n Email/Username = $email\n Password = $USERPASS\n\n" > ~/Documents/Emailfile.txt
        cat ~/Documents/Emailfile.txt
#        cat ~/Documents/Emailfile.txt | mail -s "Your LDAP account is created" $email
    fi

done
