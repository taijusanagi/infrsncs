//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AsciiString.sol";

library Image {
    function generateSVG(bytes memory sound)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '<svg width=\\"350\\" height=\\"350\\" viewBox=\\"0 0 350 350\\" xmlns=\\"http://www.w3.org/2000/svg\\"><style>@font-face{font-family: \\"VT323\\"; font-style: normal; font-weight: 400; src: url(data:font/woff2;base64,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) format(\\"woff2\\");}div{width: 350px; height: 350px; padding-top: 2px; background: black; font-family: VT323; color: white; word-break: break-all; animation-duration: 0.01s; animation-name: textflicker; animation-iteration-count: infinite; animation-direction: alternate;}h1{font-size: 24px;}p{font-size: 3px;}@keyframes textflicker{from{text-shadow: 1px 0 0 #ea36af, -2px 0 0 #75fa69;}to{text-shadow: 2px 0.5px 2px #ea36af, -1px -0.5px 2px #75fa69;}}</style><foreignObject x=\\"0\\" y=\\"0\\" width=\\"350\\" height=\\"350\\"><div xmlns=\\"http://www.w3.org/1999/xhtml\\"><h1>CHAIN BEATS</h1><p>',
                AsciiString.toAsciiString(sound),
                "</p></div></foreignObject></svg>"
            );
    }
}
