//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library SVG {
    function generate(bytes memory wave)
        internal
        pure
        returns (bytes memory svg)
    {
        svg = abi.encodePacked(
            '<svg width=\\"350\\" height=\\"350\\" viewBox=\\"0 0 350 350\\" xmlns=\\"http://www.w3.org/2000/svg\\"><style>@font-face{font-family: \\"VT323\\"; font-style: normal; font-weight: 400; src: url(data:font/woff2;base64,d09GMgABAAAAAAPAAA4AAAAADNAAAANsAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGhYbHhwoBmAAXBEICpBEjR8LGAABNgIkAxgEIAWDMAcgGyAKyAQeeL33z01elVcj361TAROk7YOetBHYvtfmaK1lsfqRLNYIlUSsayc2iEjnSL7ytoImPgU8mTRIRFLnBV5XA/Bgs7cjAEvEaQkBoSLgD58peOKJyMgqqMAcw9dRXadQvX0mM5Hy9t0Nw71Y8wI+bBCrxWpMQFoq1UCSH2wRtYTxCxdMLDAHm/FOZX51ERdgqpOs6jGww2DLLxWxjmsTqyVtVkWubUwQOvKxgIKBnNCa+UrCFJV0MsmliIr6/FwllUxyKKJc1/WP+kX9gn5OP6UfSymYeYHQdWwwNnKJcy+1yuq4HEkCAzmWSuet71Y4JtnbVyX1Js2vSvjsuoHZrspWMcdFiJQH8UU3hryLCTJgTPQsEz8nwowbv0t+3ljPLPNVGtVWVOOTqp01PnnACE1Z0nJ9V1V5P1tZFfkGsBz16mdnpbK6MQvyUP09P8ER83BTPqpzFxssIjQltho5i1JBwSm+nlKl+MaoqyxF9R/a55lhUCqsG9sgmZvKweTA4Xtji0cCn1ltoKteS3Z10Uo0F9dkJ9r9IL5k3iE4IlGicULk6II3soeJkcV/tCT0aaarRPPNfEkEM9eslU61K/Xcaufq1e6WV97jL4u07aJHN57A1/VY7gVu/AclrfFr5t9F47DIrp9lYNf5V5Xh1z9+eJGu+3kKjlaSym33RylqJSTzblwkoLj51oS0kKBaE2pUSl0hbB7Qniy+QVIHmicMeHew3bdtNXS9HwX4VZhe0mL9xviCb/dzw+r3KR3uS6brlzaePBgCQybBZkqyK8fwZxJ8jHxsW2eT8N9cln+8W3m8t/dg8OCTqcveTXbrtmKfwRYiMxpNQQ/Ve4jVk936D7Hv6BsVq4N4uhUWQFp/w6S7GXmJKdcwT0MP4BlzWqPIcLDPz+aW1ilQuNApYc2hThmNuZ0G3GmvM2kqqjNtigit+d9AO8MM008cIYQwRBODdNDPMBSCGfrbboLpY5A2QigmiwKqqCCcMMIJoowW2hihmwYGqRLiwRRP9dGLShjBaBanDqRyv/9rPJXkU00R8flLS/Mo+XT66Gei7nFbm3DZ/TVCCSUQdbqdFl6oRVii5fvopIUmaj6VEYZpb+tTQ6j40k8Lwy2aDaa9xN3dpNBHB13edDBNwmwPflcnJK3r8wmbS6IJAAAA) format(\\"woff2\\");}div{width: 350px; height: 350px; background: black; color: white; word-break: break-all; letter-spacing: 4px; animation-duration: 0.01s; animation-name: textflicker; animation-iteration-count: infinite; animation-direction: alternate; display: flex; align-items: center;}h1{padding: 0px 20px; font-family: VT323; font-size: 48px; position: absolute; top: 0;}p{font-size: 2px;}@keyframes textflicker{from{text-shadow: 1px 0 0 #ea36af, -2px 0 0 #75fa69;}to{text-shadow: 2px 0.5px 2px #ea36af, -1px -0.5px 2px #75fa69;}}</style><foreignObject x=\\"0\\" y=\\"0\\" width=\\"350\\" height=\\"350\\"><div xmlns=\\"http://www.w3.org/1999/xhtml\\"><h1>CHAIN BEATS</h1><p>',
            wave,
            "</p></div></foreignObject></svg>"
        );
    }
}
