//SPDX-License-Identifier:MIT
pragma solidity 0.8.4;

library SVG {
    function generate(bytes memory wave) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<svg width=\\"350\\"height=\\"350\\"viewBox=\\"0 0 350 350\\"xmlns=\\"http://www.w3.org/2000/svg\\"><style>div{width:350px;height:350px;background:black;color:white;word-break:break-all;font-size:2px;letter-spacing:4px;animation-duration:0.01s;animation-name:textflicker;animation-iteration-count:infinite;animation-direction:alternate;display:flex;align-items:center;}@keyframes textflicker{from{text-shadow:1px 0 0 #ea36af, -2px 0 0 #75fa69;}to{text-shadow:2px 0.5px 2px #ea36af, -1px -0.5px 2px #75fa69;}}</style><foreignObject x=\\"0\\"y=\\"0\\"width=\\"350\\"height=\\"350\\"><div xmlns=\\"http://www.w3.org/1999/xhtml\\">',
                wave,
                "</div></foreignObject></svg>"
            );
    }
}
