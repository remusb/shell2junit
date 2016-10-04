#!/bin/bash

###
### A library for shell scripts which creates reports in jUnit format.
### These reports can be used in Jenkins, or any other CI.
###
### Usage:
###     - Include this file in your shell script
###     - Use jbLog to call your command any time you want to produce a new report
###        Usage:   juLog <options> command arguments
###           options:
###             -class="MyClass" : a class name which will be shown in the junit report
###             -name="TestName" : the test name which will be shown in the junit report
###     - Junit reports are left in the folder 'result' under the directory where the script is executed.
###     - Configure Jenkins to parse junit files from the generated folder
###

# create output folder
resDir="$(pwd)/results"
mkdir -p "$resDir" || exit

DO_NOT_EXIT_ON_FAILURE=false
date=`which date`

suite=""
name=""
class=""

# Method to clean old tests
jbLogClean() {
  rm -f "$resDir"/*.xml
}

jbLogContains() {
  suite=""
  name=""
  class=""
  error_count=0

  # parse arguments
  ya=""; icase=""; passon="eq"
  while [ -z "$ya" ]; do
    case "$1" in
      -name=*)   name=`echo "$1" | sed -e 's/-name=//'`;   shift;;
      -class=*)  class=`echo "$1" | sed -e 's/-class=//'`;   shift;;
      -passon=*)  passon=`echo "$1" | sed -e 's/-passon=//'`;   shift;;
      *)         ya=1;;
    esac
  done

  # use first arg as name if it was not given
  if [ -z "$name" ]; then
    name="00-$1"
    shift
  fi

  if [[ "$class" = "" ]]; then
    class="default"
  fi

  suite=$class
  
  # echo "name is: $name"
  # echo "class is: $class"

  # calculate command to eval
  [ -z "$1" ] && return
  a="$1";
  b="$2";

  # eval the command sending output to a file
  outf=/tmp/junit$$.txt
  errf=/tmp/junit$$-err.txt

  # echo "+++ Running case: $class.$name "
  # echo "+++ working dir: "`pwd`

  ini=`$date +%s`
  if [[ "$a" == *"$b"* ]] && [[ "$passon" == "eq" ]]; then
    err=0
    outMsg="$a == *$b*"
    errMsg=""
  elif [[ "$a" != *"$b"* ]] && [[ "$passon" == "neq" ]]; then
    err=0
    outMsg="$a != *$b*"
    errMsg=""
  else
    err=1
    outMsg=""
    errMsg="$a $passon *$b*"
  fi
  end=`$date +%s`
  
  # echo "+++ exit code: $err"

  # calculate vars
  spent=$(($end-$ini))
  total=spent
  asserts=1
  error_count=0

  if [[ $err > 0 ]]; then
    error_count=1
  fi

  jbLogWrite "$suite" "$name" "$class" "$outMsg" "$errMsg" $err $spent $error_count
}

jbLogEquals() {
  suite=""
  name=""
  class=""
  error_count=0

  # parse arguments
  ya=""; icase=""; passon="eq"
  while [ -z "$ya" ]; do
    case "$1" in
      -name=*)   name=`echo "$1" | sed -e 's/-name=//'`;   shift;;
      -class=*)  class=`echo "$1" | sed -e 's/-class=//'`;   shift;;
      -passon=*)  passon=`echo "$1" | sed -e 's/-passon=//'`;   shift;;
      *)         ya=1;;
    esac
  done

  # use first arg as name if it was not given
  if [ -z "$name" ]; then
    name="00-$1"
    shift
  fi

  if [[ "$class" = "" ]]; then
    class="default"
  fi

  suite=$class
  
  # echo "name is: $name"
  # echo "class is: $class"

  # calculate command to eval
  [ -z "$1" ] && return
  a="$1";
  b="$2";

  # eval the command sending output to a file
  outf=/tmp/junit$$.txt
  errf=/tmp/junit$$-err.txt

  # echo "+++ Running case: $class.$name "
  # echo "+++ working dir: "`pwd`

  ini=`$date +%s`
  if [[ "$a" == "$b" ]] && [[ "$passon" == "eq" ]]; then
    err=0
    outMsg="$a == $b"
    errMsg=""
  elif [[ "$a" != "$b" ]] && [[ "$passon" == "neq" ]]; then
    err=0
    outMsg="$a != $b"
    errMsg=""
  else
    err=1
    outMsg=""
    errMsg="$a $passon $b"
  fi
  end=`$date +%s`
  
  # echo "+++ exit code: $err"

  # calculate vars
  spent=$(($end-$ini))
  total=spent
  asserts=1
  error_count=0

  if [[ $err > 0 ]]; then
    error_count=1
  fi

  jbLogWrite "$suite" "$name" "$class" "$outMsg" "$errMsg" $err $spent $error_count
}

# Execute a command and record its results
jbLogEval() {
  suite=""
  name=""
  class=""
  error_count=0

  # parse arguments
  ya=""; icase=""; failstring=""; passstring=""
  while [ -z "$ya" ]; do
    case "$1" in
      -name=*)   name=`echo "$1" | sed -e 's/-name=//'`; shift;;
      -class=*)  class=`echo "$1" | sed -e 's/-class=//'`; shift;;
      -failstring=*) failstring=`echo "$1" | sed -e 's/-failstring=//'`; shift;;
      -passstring=*)  passstring=`echo "$1" | sed -e 's/-passstring=//'`; shift;;
      -ifailstring=*) failstring=`echo "$1" | sed -e 's/-ifailstring=//'`; icase="-i"; shift;;
      -ipassstring=*)  passstring=`echo "$1" | sed -e 's/-ipassstring=//'`; icase="-i"; shift;;
      *)         ya=1;;
    esac
  done

  # use first arg as name if it was not given
  if [ -z "$name" ]; then
    name="00-$1"
    shift
  fi

  if [[ "$class" = "" ]]; then
    class="default"
  fi

  suite=$class

  # echo "name is: $name"
  # echo "class is: $class"

  # calculate command to eval
  [ -z "$1" ] && return
  cmd="$1"; shift
  while [ -n "$1" ]
  do
     cmd="$cmd \"$1\""
     shift
  done

  # eval the command sending output to a file
  outf=/tmp/junit$$.txt
  errf=/tmp/junit$$-err.txt

  # echo "+++ Running case: $class.$name "
  # echo "+++ working dir: "`pwd`
  echo "+++ command: $cmd"

  # execute the command
  revert_error=false
  if [[ "$-" == *"e"* ]]; then
    set +e
    revert_error=true
  fi

  ini=`$date +%s`
  eval "$cmd" 2>$errf 1>$outf
  err=$?
  end=`$date +%s`

  if [[ "$revert_error" == true ]]; then
    set -e
  fi
  
  sed -r -e "s/\x1B\[[0-9]+m//g" -i $errf
  sed -r -e "s/\x1B\[[0-9]+m//g" -i $outf
  errMsg="$(cat $errf)"
  outMsg="$(cat $outf)"
  rm -f $outf
  rm -f $errf

  if [[ $err == 0 ]] && [[ -n "$failstring" ]]; then
    H=$(echo "$outMsg" | grep $icase "$failstring" || true)

    if [[ -n "$H" ]]; then
      err=1
      errMsg="$failstring found in output"
    fi
  fi

  if [[ $err == 0 ]] && [[ -n "$passstring" ]]; then
    H=$(echo "$outMsg" | grep $icase "$passstring" || true)

    if [[ -z "$H" ]]; then
      err=1
      errMsg="$passstring not found in output"
    fi
  fi

  # echo "+++ exit code: $err"

  # calculate vars
  spent=$(($end-$ini))
  total=spent
  asserts=1
  error_count=0

  if [[ $err > 0 ]]; then
    error_count=1
  fi

  jbLogWrite "$suite" "$name" "$class" "$outMsg" "$errMsg" $err $spent $error_count
}

jbLogWrite() {
  suite=$1
  name=$2
  class=$3
  outMsg=$4
  errMsg=$5
  err=$6
  spent=$7
  error_count=$8

  # write the junit xml report
  ## failure tag
  [ $err = 0 ] && failure="" || failure="
      <failure type=\"ScriptError\" message=\"Script Error\">
<![CDATA[
$errMsg
]]>
      </failure>
  "
  ## testcase tag
  content="
    <testcase assertions=\"1\" name=\"$name\" time=\"$spent\">
    $failure
    <system-out>
<![CDATA[
$outMsg
]]>
    </system-out>
    <system-err>
<![CDATA[
$errMsg
]]>
    </system-err>
    </testcase>
  "
  ## testsuite block

  if [[ -e "$resDir/$suite.xml" ]]; then
    existing_assertions=$(cat $resDir/$suite.xml | sed -n '1 s/.*assertions="\([^"]*\).*/\1/p')
    existing_tests=$(cat $resDir/$suite.xml | sed -n '1 s/.*tests="\([^"]*\).*/\1/p')
    # existing_errors=$(cat $resDir/$suite.xml | sed -n '1 s/.*errors="\([^"]*\).*/\1/p')
    existing_time=$(cat $resDir/$suite.xml | sed -n '1 s/.*time="\([^"]*\).*/\1/p')

    existing_errors=$(($existing_errors+$error_count))
    existing_assertions=$(($existing_assertions+1))
    existing_tests=$(($existing_tests+1))
    existing_time=$(($existing_time+$total))

    sed -i "1s/<testsuite\([^>]*\)>/<testsuite failures=\"$existing_errors\" assertions=\"$existing_assertions\" name=\"$suite\" tests=\"$existing_tests\" errors=\"0\" time=\"$existing_time\">/" $resDir/$suite.xml
    sed -i '/<\/testsuite>/d' $resDir/$suite.xml ## remove testSuite so we can add it later
    cat <<EOF >> "$resDir/$suite.xml"
     $content
    </testsuite>
EOF
  else
    # no file exists. Adding a new file
    cat <<EOF > "$resDir/$suite.xml"
    <testsuite failures="$error_count" assertions="1" name="$suite" tests="1" errors="0" time="$total">
    $content
    </testsuite>
EOF
  fi

  if [[ $err > 0 ]] && [[ "$DO_NOT_EXIT_ON_FAILURE" == false ]]; then
    exit $err
  fi
}
