//
//  ConversationTableViewCell.swift
//  ChatAppAES
//
//  Created by quynb on 18/01/2022.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {
    @IBOutlet weak var lastest_message: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var nameUser: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
