import elliptic from 'elliptic';
const ec = new elliptic.ec('secp256k1');
const privKey = '92d1684e667260ee6f6d03bf2d072a6f902c4296047b7171cc0f4918c776b122';
const key = ec.keyFromPrivate(privKey, 'hex');
const pub = key.getPublic().encode('hex', false).slice(2);
console.log(pub); 