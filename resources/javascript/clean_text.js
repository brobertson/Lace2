function check_for_mixed_latin_greek(textIn) {
    return textIn
}

function check_for_improperly_composed_greek(textIn) {
    textIn_nfc = textIn.normalize('NFC');
    if (/[\u0300-\u0302]/.test(textIn_nfc) || /[\u0342-\u0345]/.test(textIn_nfc)) {
        char_dump = ""
        for (var i = 0; i < textIn_nfc.length; i++) {
            char_dump = char_dump + ' \\u' + (textIn_nfc[i].charCodeAt(0)  + 0x10000).toString(16).slice(1)
        }
        alert("it appers this is improperly composed Greek:" + char_dump)
    }
}

function clean_text(textIn) {
    //replace no break space with space
    textIn = textIn.replace(/\u00A0/g,' ')
    //erase unknown character and multiplication sign
    textIn = textIn.replace(/[\uFFFD\u00D7]/g,'')
    //change MODIFIER LETTER APOSTROPHE, APOSTROPHE, GREEK KORONIS to RIGHT SINGLE QUOTATION MARK
    textIn = textIn.replace(/[ʼ'᾽]/g,'’')
    //change ANO TELEIA, DOT OPERATOR to MIDDLE DOT
    textIn = textIn.replace(/[⋅·]/g,'·')
    //replace '<'  and MATHEMATICAL LEFT ANGLE BRACKET 27E8 with LEFT ANGLE BRACKET 3008
    textIn = textIn.replace(/[\u003C\u27E8]/g,'\u3008')
    //replace '>' and MATHEMATICAL RIGHT ANGLE BRACKET 27E9 with RIGHT ANGLE BRACKET 3009
    textIn = textIn.replace(/[\u003E\u27E9]/g,'\u3009')
    //replace em-dash and en-dash with hyphen
    textIn = textIn.replace(/—–/g,'-')
    //delete 1fbe GREEK PROSGEGRAMMENI
    if (textIn.includes('\u1FBE')) {
        alert("Do not use U+1FBE GREEK PROSGEGRAMMENI to edit these texts. Consult with your guide documents and use U+0345 IOTA SUBSCRIPT instead.")
    }
    textIn = textIn.replace(/\u1FBE/g,'')
    check_for_improperly_composed_greek(textIn)
    return textIn
}
