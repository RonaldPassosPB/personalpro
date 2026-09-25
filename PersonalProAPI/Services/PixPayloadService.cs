using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace PersonalProAPI.Services
{
    public static class PixPayloadService
    {
        public static string GerarPayload(string chavePix, string nomeBeneficiario, string cidade, decimal valor, string identificador)
        {
            if (string.IsNullOrWhiteSpace(chavePix))
                chavePix = "personal@personalpro.com";

            nomeBeneficiario = SanitizarTexto(nomeBeneficiario, 25);
            cidade = SanitizarTexto(cidade, 15);
            if (string.IsNullOrWhiteSpace(cidade)) cidade = "SAO PAULO";
            if (string.IsNullOrWhiteSpace(nomeBeneficiario)) nomeBeneficiario = "PERSONALPRO";

            identificador = Regex.Replace(identificador ?? "PPRO01", "[^a-zA-Z0-9]", "");
            if (identificador.Length > 25) identificador = identificador[..25];
            if (string.IsNullOrEmpty(identificador)) identificador = "PPRO01";

            var gui = FormatTlv("00", "br.gov.bcb.pix");
            var chave = FormatTlv("01", chavePix.Trim());
            var merchantAccount = FormatTlv("26", gui + chave);

            var txId = FormatTlv("05", identificador);
            var additionalData = FormatTlv("62", txId);

            var sb = new StringBuilder();
            sb.Append(FormatTlv("00", "01"));
            sb.Append(merchantAccount);
            sb.Append(FormatTlv("52", "0000"));
            sb.Append(FormatTlv("53", "986"));
            sb.Append(FormatTlv("54", valor.ToString("F2", CultureInfo.InvariantCulture)));
            sb.Append(FormatTlv("58", "BR"));
            sb.Append(FormatTlv("59", nomeBeneficiario));
            sb.Append(FormatTlv("60", cidade));
            sb.Append(additionalData);
            sb.Append("6304");

            var payloadSemCrc = sb.ToString();
            var crc = CalcularCrc16(payloadSemCrc);
            return payloadSemCrc + crc.ToString("X4");
        }

        private static string FormatTlv(string id, string value)
        {
            var len = Encoding.UTF8.GetByteCount(value);
            return $"{id}{len:D2}{value}";
        }

        private static string SanitizarTexto(string texto, int maxLength)
        {
            if (string.IsNullOrWhiteSpace(texto)) return "";
            var normalizado = texto.Normalize(NormalizationForm.FormD);
            var sb = new StringBuilder();
            foreach (var c in normalizado)
            {
                var unicodeCategory = CharUnicodeInfo.GetUnicodeCategory(c);
                if (unicodeCategory != UnicodeCategory.NonSpacingMark && (char.IsLetterOrDigit(c) || c == ' '))
                {
                    sb.Append(c);
                }
            }
            var limpo = sb.ToString().ToUpperInvariant().Trim();
            return limpo.Length > maxLength ? limpo[..maxLength] : limpo;
        }

        private static ushort CalcularCrc16(string str)
        {
            ushort crc = 0xFFFF;
            var bytes = Encoding.ASCII.GetBytes(str);
            foreach (var b in bytes)
            {
                crc ^= (ushort)(b << 8);
                for (int i = 0; i < 8; i++)
                {
                    if ((crc & 0x8000) != 0)
                        crc = (ushort)((crc << 1) ^ 0x1021);
                    else
                        crc <<= 1;
                }
            }
            return crc;
        }
    }
}
