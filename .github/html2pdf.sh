#!/bin/bash

# run: . html2pdf.sh input.html output.pdf

if [[ "$#" > 1 ]]; then
    title="$(php -r 'echo html_entity_decode($argv[1], ENT_QUOTES|ENT_HTML5, "UTF-8")."\n";' "$(sed -En -e 's/^.*<title>(.*)<\/title>.*$/\1/p' "${1}")")"
    author="$(php -r 'echo html_entity_decode(rawurldecode($argv[1]), ENT_QUOTES|ENT_HTML5, "UTF-8")."\n";' "$(sed -En -e 's/^.*<link rel="author" href="mailto:([^"]*)".*/\1/p' "${1}")")"
    if [ -z "${author}" ]; then
        author="$(php -r 'echo html_entity_decode($argv[1], ENT_QUOTES|ENT_HTML5, "UTF-8")."\n";' "$(sed -En -e 's/^.*<meta name="author" content="([^"]*)".*/\1/p' "${1}")")"
    fi
    subject="$(php -r 'echo html_entity_decode($argv[1], ENT_QUOTES|ENT_HTML5, "UTF-8")."\n";' "$(sed -En -e 's/^.*<meta name="description" lang="[^"]*" content="([^"]*)".*/\1/p' "${1}")")"
    keywords="$(php -r 'echo implode("|[SEPARATOR]|", preg_split("/\s*,[\s,]*/", html_entity_decode($argv[1], ENT_QUOTES|ENT_HTML5, "UTF-8"), -1, PREG_SPLIT_NO_EMPTY))."\n";' "$(sed -En -e 's/^.*<meta name="keywords" lang="[^"]*" content="([^"]*)".*/\1/p' "${1}")")"
    generator="$(php -r 'echo html_entity_decode($argv[1], ENT_QUOTES|ENT_HTML5, "UTF-8")."\n";' "$(sed -En -e 's/^.*<meta name="generator" lang="[^"]*" content="([^"]*)".*/\1/p' "${1}")")"
    if [[ -z "${generator}" ]]; then
        generator='-'
    fi
    wkhtmltopdf \
        --load-error-handling 'abort' --load-media-error-handling 'abort' \
        --print-media-type --minimum-font-size 1 \
        -B 10mm -L 10mm -R 10mm -T 10mm -O Landscape -s A4 \
        --no-stop-slow-scripts \
        --run-script 'window.setTimeout(function(){window.status = "FOOBAR";}, 1000);' --window-status 'FOOBAR' \
        --title "${title}" "${1}" "${tmp}" \
    && exiftool \
        -z -P -sep "|[SEPARATOR]|" \
        -XMP:Format="application/pdf" \
        -Title="${title}" \
        -PDF:Subject="${subject}" -XMP:Description="${subject}" \
        -PDF:Author="${author}" -XMP:Creator="${author}" \
        -XMP:Keywords="${keywords//|\[SEPARATOR\]|/, }" -PDF:Keywords="${keywords//|\[SEPARATOR\]|/, }" \
        -XMP:Subject="${keywords//"\""/}" -AppleKeywords="${keywords//|\[SEPARATOR\]|/, }" \
        -XMP:Marked=True \
        -XMP:DocumentID="$([ -f "${2}" ] && exiftool -q -z -P -s3 -XMP:DocumentID "${2}" || exiftool -q -z -P -p 'uuid:$ExifTool:newguid' "${tmp}")" \
        -XMP:InstanceID="uuid:$(exiftool -q -z -P -s3 -ExifTool:newguid "${tmp}")" \
        -PDF:Creator="${generator}" -XMP:CreatorTool="${generator}" \
        -Producer="$(exiftool -q -z -P -p '$PDF:Creator / $PDF:Producer' "${tmp}")" \
        -CreateDate="$([ -f "${2}" ] && exiftool -q -z -P -s3 -PDF:CreateDate "${2}" || exiftool -q -z -P -s3 -PDF:CreateDate "${tmp}")" '-ModifyDate<PDF:CreateDate' '-XMP:MetadataDate<PDF:CreateDate' \
        -overwrite_original_in_place "${tmp}" \
        "${tmp}" "${tmp2}"
    if [[ $? -lt 1 ]]; then
        cp -f "${tmp2}" "${2}"
    else
        echo 'Some error occured' 1>&2
    fi
    if [[ -f "${tmp}" ]]; then
        rm -f "${tmp}"
    fi
    if [[ -f "${tmp2}" ]]; then
        rm -f "${tmp2}"
    fi
else
    echo "2 parameters expected, only got $#" 1>&2
fi
